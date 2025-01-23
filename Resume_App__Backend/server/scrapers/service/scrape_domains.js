import puppeteer from 'puppeteer-extra';
import StealthPlugin from 'puppeteer-extra-plugin-stealth';
import axios from 'axios';
import * as cheerio from 'cheerio';
import { URL } from 'url';

// Use stealth to reduce detection
puppeteer.use(StealthPlugin());

/**
 * Main function to find a company's domain:
 * 1) Generate TLD guesses -> check quickly (HTTP/HTTPS).
 * 2) If not found, scrape search engines (DuckDuckGo + Bing), in parallel (faster).
 * 3) Validate results, pick best match via content rank.
 */
export async function findCompanyDomain(companyName) {
  // 1. Quick TLD guess approach
  const guessList = generateDomainGuesses(companyName);
  const validGuess = await pickBestValidDomain(companyName, guessList);
  if (validGuess) {
    // Found from TLD guess, no need to open the browser
    return validGuess;
  }

  // 2. Scrape multiple search engines with Puppeteer, gather domain candidates
  const searchDomains = await scrapeSearchEngines(companyName);
  if (searchDomains.length === 0) {
    return null; // No domains found from scraping
  }

  // 3. Validate/rank scraped domains, return best
  const bestScraped = await pickBestValidDomain(companyName, searchDomains);
  return bestScraped || null;
}

/**
 * Creates a broad set of domain guesses using known TLDs
 * and variants of the company name (spaces removed/hyphens, suffix removal, etc.).
 */
function generateDomainGuesses(companyName) {
  let base = companyName.toLowerCase();
  // Remove typical suffixes (inc, ltd, etc.)
  base = base.replace(/\b(inc|llc|ltd|gmbh|co|corp|sa|plc)\b/g, '');
  // Remove punctuation/special chars
  base = base.replace(/[^a-z0-9\s]+/g, '').trim();

  const words = base.split(/\s+/).filter(Boolean);
  const joinedNoSpace = words.join('');
  const joinedHyphen = words.join('-');

  // Expanded TLD list (add or remove as desired)
  const tlds = [
    '.com', '.net', '.org', '.io', '.co', '.ai', '.us', '.uk', '.eu', '.tech',
    '.dev', '.app', '.biz', '.info', '.me', '.ly', '.in', '.au', '.ca', '.de',
    '.fr', '.jp', '.kr', '.ua', '.pk', '.ph'
  ];

  const guesses = new Set();
  for (const tld of tlds) {
    guesses.add(joinedNoSpace + tld);
    guesses.add(joinedHyphen + tld);
    if (words.length > 1) {
      guesses.add(words[0] + tld); // partial
    }
  }

  return Array.from(guesses);
}

/**
 * Ranks each domain candidate to see if it is a valid match:
 *  - Check HTTP/HTTPS reachability
 *  - Scrape homepage text for matches to synonyms
 * Returns the highest-ranked domain, or null if none are valid.
 */
async function pickBestValidDomain(companyName, domains) {
  const tasks = domains.map(async (d) => {
    const rank = await rankDomain(d, companyName);
    return { domain: d, rank };
  });

  const results = await Promise.all(tasks);
  const valid = results.filter((r) => r.rank >= 0);
  valid.sort((a, b) => b.rank - a.rank); // descending by rank
  return valid.length > 0 ? valid[0].domain : null;
}

/**
 * Attempts to connect via HTTP, then HTTPS if HTTP fails.
 * If reachable, fetch homepage HTML and look for mention of company synonyms.
 * Returns -1 if invalid/unreachable, or >= 0 for valid domain, higher = more likely match.
 */
async function rankDomain(domain, companyName) {
  // 1) Try connecting over HTTP, else fallback to HTTPS
  let isReachable = false;
  let finalUrl = `http://${domain}`;

  // Try HEAD on http
  isReachable = await testReachability(finalUrl);
  if (!isReachable) {
    // Try https
    finalUrl = `https://${domain}`;
    isReachable = await testReachability(finalUrl);
  }

  if (!isReachable) {
    return -1;
  }

  // 2) If reachable, fetch content & rank
  let score = 1; // base score for a live domain
  try {
    const resp = await axios.get(finalUrl, { timeout: 5000 });
    if (resp.status === 200 && resp.data) {
      const text = resp.data.toLowerCase();
      const synonyms = buildSynonyms(companyName);

      // for each matched synonym in body => +2 points
      for (const syn of synonyms) {
        if (text.includes(syn.toLowerCase())) {
          score += 2;
        }
      }

      // check <title> => +5 points if matched
      const $ = cheerio.load(resp.data);
      const title = $('title').text().toLowerCase();
      for (const syn of synonyms) {
        if (title.includes(syn.toLowerCase())) {
          score += 5;
        }
      }
    }
  } catch (err) {
    // homepage fetch error => partial credit
  }

  return score;
}

/**
 * Helper: quickly tests if a domain is reachable (HEAD or fallback GET).
 * Returns true if we get a 2xx or 3xx status.
 */
async function testReachability(url) {
  try {
    let resp = await axios.head(url, { timeout: 4000, maxRedirects: 2 });
    if (resp.status >= 200 && resp.status < 400) {
      return true;
    }
    // fallback GET
    resp = await axios.get(url, { timeout: 4000, maxRedirects: 2 });
    return (resp.status >= 200 && resp.status < 400);
  } catch {
    return false;
  }
}

/**
 * Creates synonyms for the given company name: 
 * e.g. "OpenAI Inc" => "openai inc", "openai", "open-ai"
 */
function buildSynonyms(companyName) {
  let cleaned = companyName.replace(/[^\w\s-]+/g, '').toLowerCase();
  cleaned = cleaned.replace(/\b(inc|llc|ltd|gmbh|co|corp|sa|plc)\b/g, '').trim();

  const words = cleaned.split(/\s+/).filter(Boolean);
  const synonyms = new Set();
  synonyms.add(cleaned);
  synonyms.add(words.join('-'));
  synonyms.add(words.join(''));
  if (words.length > 1) {
    synonyms.add(words[0]); // partial
  }
  return Array.from(synonyms);
}

/**
 * Scrapes multiple search engines (DuckDuckGo + Bing) in parallel using Puppeteer.
 * Returns an array of domain strings discovered.
 */
async function scrapeSearchEngines(companyName) {
  const browser = await puppeteer.launch({
    headless: false,        // So we can solve captchas manually
    defaultViewport: null   // Use entire screen
    // userDataDir: "path/to/cache", // optional for persistent sessions
  });

  // We create two tabs/pages, do each search in parallel for speed
  let ddgDomains = [];
  let bingDomains = [];

  try {
    const [page1, page2] = await Promise.all([
      browser.newPage(),
      browser.newPage()
    ]);

    // Set user-agents & random delay on each page
    await Promise.all([
      setRandomUserAgent(page1),
      setRandomUserAgent(page2)
    ]);

    // Perform parallel searches
    [ddgDomains, bingDomains] = await Promise.all([
      scrapeDuckDuckGo(page1, companyName),
      scrapeBing(page2, companyName)
    ]);

    await page1.close();
    await page2.close();
  } catch (err) {
    console.error('Error scraping search engines:', err);
  } finally {
    await browser.close();
  }

  // Merge & deduplicate
  const combined = new Set([...ddgDomains, ...bingDomains]);
  return Array.from(combined);
}

/**
 * We replace page.waitForTimeout with a custom delay to support older Puppeteer versions.
 */
function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Sets a random user agent, plus a small random delay, to avoid being flagged.
 */
async function setRandomUserAgent(page) {
  const userAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
      '(KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' +
      '(KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 ' +
      '(KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36'
  ];
  const randomUA = userAgents[Math.floor(Math.random() * userAgents.length)];
  await page.setUserAgent(randomUA);

  // Shorter random delay than before => faster but riskier
  const randomMs = Math.floor(Math.random() * 1500) + 500; // 0.5s - 2s
  await delay(randomMs);
}

/**
 * Searches DuckDuckGo. If captcha appears, waits for user to solve it.
 */
async function scrapeDuckDuckGo(page, companyName) {
  const results = [];
  try {
    const query = encodeURIComponent(`${companyName} official website`);
    const ddgUrl = `https://duckduckgo.com/?q=${query}&t=h_&ia=web`;

    await page.goto(ddgUrl, { waitUntil: 'networkidle2', timeout: 12000 });

    const captchaSelector = '[id*="captcha"]';
    const resultsSelector = '.result__url, .result__a';

    // Wait for either captcha or results
    const firstElement = await Promise.race([
      page.waitForSelector(captchaSelector, { timeout: 5000 }).catch(() => null),
      page.waitForSelector(resultsSelector, { timeout: 5000 }).catch(() => null)
    ]);

    if (firstElement) {
      // If captcha
      const isCaptcha = await page.$(captchaSelector);
      if (isCaptcha) {
        console.log('DuckDuckGo captcha detected. Please solve it in the browser...');
        await waitForManualSolve(page, resultsSelector);
      }
    }

    // Now parse the results
    const html = await page.content();
    const $ = cheerio.load(html);
    const linkEls = $('.result__url, .result__a');
    linkEls.each((i, el) => {
      const href = $(el).attr('href');
      if (href) {
        const domain = extractDomain(href);
        if (domain) results.push(domain);
      }
    });
  } catch (err) {
    console.error('DuckDuckGo scrape failed:', err);
  }
  return results;
}

/**
 * Searches Bing in parallel. If captcha appears, waits for user solve.
 */
async function scrapeBing(page, companyName) {
  const results = [];
  try {
    const query = encodeURIComponent(`${companyName} official website`);
    const bingUrl = `https://www.bing.com/search?q=${query}`;

    await page.goto(bingUrl, { waitUntil: 'networkidle2', timeout: 12000 });

    const captchaSelector = 'img[id="b_captcha"]';
    const resultsSelector = 'li.b_algo h2 a';

    const firstElement = await Promise.race([
      page.waitForSelector(captchaSelector, { timeout: 5000 }).catch(() => null),
      page.waitForSelector(resultsSelector, { timeout: 5000 }).catch(() => null)
    ]);

    if (firstElement) {
      const isCaptcha = await page.$(captchaSelector);
      if (isCaptcha) {
        console.log('Bing captcha detected. Please solve it in the browser...');
        await waitForManualSolve(page, resultsSelector);
      }
    }

    const html = await page.content();
    const $ = cheerio.load(html);
    const linkEls = $('li.b_algo h2 a');
    linkEls.each((i, el) => {
      const href = $(el).attr('href');
      if (href) {
        const domain = extractDomain(href);
        if (domain) results.push(domain);
      }
    });
  } catch (err) {
    console.error('Bing scrape failed:', err);
  }
  return results;
}

/**
 * Simple loop that checks for successSelector (meaning captcha is solved).
 * The user must manually solve in the open browser window.
 */
async function waitForManualSolve(page, successSelector) {
  let solved = false;
  while (!solved) {
    try {
      await page.waitForSelector(successSelector, { timeout: 5000 });
      solved = true;
      console.log('Captcha solved. Proceeding...');
    } catch {
      console.log('Still waiting for captcha to be solved...');
    }
  }
}

/**
 * Extract domain from a given URL, ignoring protocol/path.
 */
function extractDomain(link) {
  try {
    const parsed = new URL(link);
    return parsed.hostname.toLowerCase();
  } catch {
    return null;
  }
}

// Example usage (uncomment to test):
/*
(async () => {
  const testCompany = 'Bank-e-Millie Afghan';
  console.time('findDomain');
  const domain = await findCompanyDomain(testCompany);
  console.timeEnd('findDomain');
  console.log(`Domain for "${testCompany}":`, domain || 'Not found');
})();
*/
