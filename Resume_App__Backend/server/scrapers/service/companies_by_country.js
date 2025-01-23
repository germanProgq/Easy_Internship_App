import axios from "axios";
import { load } from "cheerio";
import fs from "fs";
import path from "path";

/** 
 * HELPER to check if a category link is likely relevant:
 *   We'll do a simple check to see if the subcategory link text includes "company" or "companies".
 *   If you want stricter logic, you can do more checks.
 */
function isRelevantCategoryLink(linkHref) {
  // For example, skip if "film" or "episode" or "sports" is in the URL
  // or only proceed if we see "company", "companies", "business", etc.
  // Here is a naive approach that only allows subcategories if "company" or "companies" 
  // or "Lists_of_companies" is in the URL:
  const lower = linkHref.toLowerCase();
  if (
    lower.includes("company") ||
    lower.includes("companies") ||
    lower.includes("lists_of_companies")
  ) {
    return true;
  }
  return false;
}

/**
 * 1) Scrape one category page, returning:
 *    - subcategories
 *    - article links
 *    - nextPageUrl
 * 
 * We'll filter out subcategories that don't look relevant 
 * (e.g., subcat link doesn't contain "company" or "companies").
 */
async function scrapeCategoryPage(url) {
  console.log(`Scraping category page: ${url}`);
  const resp = await axios.get(url);
  if (resp.status !== 200) {
    throw new Error(`Non-200 response: ${resp.status} for ${url}`);
  }
  const $ = load(resp.data);

  const subcategories = [];
  const articles = [];

  $("#mw-subcategories .mw-category-group ul li a").each((_, el) => {
    const href = $(el).attr("href");
    if (!href) return;
    const fullLink = new URL(href, "https://en.wikipedia.org").href;
    // Only push subcategory if it has /wiki/Category: AND is relevant
    if (/\/wiki\/Category:/i.test(fullLink)) {
      if (isRelevantCategoryLink(fullLink)) {
        subcategories.push(fullLink);
      } else {
        // Skip subcategories that seem irrelevant
        // console.log("Skipping subcat (irrelevant):", fullLink);
      }
    }
  });

  // Articles: #mw-pages .mw-category-group
  $("#mw-pages .mw-category-group ul li a").each((_, el) => {
    const href = $(el).attr("href");
    if (!href) return;
    const fullLink = new URL(href, "https://en.wikipedia.org").href;
    // Exclude further categories—just get articles
    if (!/\/wiki\/Category:/i.test(fullLink)) {
      articles.push(fullLink);
    }
  });

  // Next page link
  let nextPageUrl = null;
  const nextLink = $("#mw-pages a")
    .filter((_, el) => /next page/i.test($(el).text()))
    .attr("href");
  if (nextLink) {
    nextPageUrl = new URL(nextLink, "https://en.wikipedia.org").href;
  }

  return { subcategories, articles, nextPageUrl };
}

/**
 * 2) BFS over an entire category with a maxDepth filter. 
 *    subcategories that aren't relevant won't be included (due to the code above).
 */
async function scrapeCategoryNoLimit(startUrl, visited = new Set(), depth = 0, maxDepth = 3) {
  const subcategoriesCollected = [];
  const articlesCollected = [];

  // We'll store multiple pages in a queue
  const queue = [{ url: startUrl, depth }];
  
  while (queue.length > 0) {
    const { url, depth: currentDepth } = queue.shift();
    if (visited.has(url)) continue;
    visited.add(url);

    // If we've hit maxDepth, skip scraping subcategories below this level
    if (currentDepth > maxDepth) {
      // If you prefer to still gather articles on the same page, do it. 
      // But typically you'd skip entire page if beyond maxDepth.
      console.log(`Skipping ${url}, depth ${currentDepth} > maxDepth ${maxDepth}`);
      continue;
    }

    try {
      const { subcategories, articles, nextPageUrl } = await scrapeCategoryPage(url);

      subcategoriesCollected.push(...subcategories);
      articlesCollected.push(...articles);

      // Enqueue subcategories if under maxDepth
      const nextDepth = currentDepth + 1;
      for (const subcat of subcategories) {
        // We'll only queue if nextDepth <= maxDepth, so we don't descend infinitely
        queue.push({ url: subcat, depth: nextDepth });
      }

      // If there's a next page, re-queue same depth
      if (nextPageUrl) {
        queue.push({ url: nextPageUrl, depth: currentDepth });
      }
    } catch (err) {
      console.error(`Error scraping ${url}:`, err);
    }
  }

  return { subcategories: subcategoriesCollected, articles: articlesCollected };
}

/**
 * 3) Parse a single “List_of_companies_of_X” or “List_of_companies_in_X” page
 */
/**
 * Decide if a given text is likely a real company name 
 * or something to skip (numeric row number, "Economy of..", "portal", etc.)
 */
function isLikelyCompanyName(str) {
  // (1) Strip extra whitespace
  const text = str.trim();
  if (!text) return false; // empty

  // (2) Skip purely numeric lines (like "1", "2", "19", etc.)
  if (/^\d+$/.test(text)) {
    return false;
  }

  // (3) Optionally skip if it's extremely short (e.g. < 2 or 3 chars)
  if (text.length < 2) {
    return false;
  }

  // (4) Check for known "non-company" keywords
  // You can expand this list as needed
  const lower = text.toLowerCase();
  if (
    lower.includes("portal") ||
    lower.includes("economy of") ||
    lower.includes("list of") ||
    lower.includes("statutory board") ||
    lower.includes("government") ||
    lower.includes("university") ||
    lower.includes("publications")
  ) {
    return false;
  }

  return true; // passes all checks -> likely a valid company
}

async function scrapeCompaniesFromPage(articleUrl) {
  try {
    console.log(`Scraping article for companies: ${articleUrl}`);
    const resp = await axios.get(articleUrl);
    if (resp.status !== 200) {
      throw new Error(`Non-200: ${resp.status} for ${articleUrl}`);
    }
    const $ = load(resp.data);

    const companies = new Set();

    // (A) .wikitable rows
    $("table.wikitable").each((_, table) => {
      const rows = $(table).find("tr").slice(1); // skip header
      rows.each((_, row) => {
        const firstCell = $(row).find("td").first();
        const link = firstCell.find("a").first();
        const text = link.length ? link.text().trim() : firstCell.text().trim();

        // Filter here
        if (isLikelyCompanyName(text)) {
          companies.add(text);
        }
      });
    });

    // (B) Bullet lists
    $(".div-col ul li, .mw-parser-output > ul li").each((_, li) => {
      const link = $(li).find("a").first();
      const text = link.length ? link.text().trim() : $(li).text().trim();
      if (isLikelyCompanyName(text)) {
        companies.add(text);
      }
    });

    // (C) Numbered lists
    $(".mw-parser-output > ol li").each((_, li) => {
      const link = $(li).find("a").first();
      const text = link.length ? link.text().trim() : $(li).text().trim();
      if (isLikelyCompanyName(text)) {
        companies.add(text);
      }
    });

    return [...companies];
  } catch (err) {
    console.error(`Error scraping article: ${articleUrl}`, err);
    return [];
  }
}


/** 
 * Simple helper: parse the "country" name from the article URL
 */
function parseCountryFromUrl(articleUrl) {
  const pathName = new URL(articleUrl).pathname;
  let pageName = decodeURIComponent(pathName.replace("/wiki/", ""));

  pageName = pageName.replace(/^List_of_companies_of_/i, "");
  pageName = pageName.replace(/^List_of_companies_in_/i, "");
  pageName = pageName.replace(/_/g, " ");
  return pageName.trim();
}

/**
 * 4) Master function: 
 *    - Start from "Lists_of_companies_by_country"
 *    - Use BFS with maxDepth=3 (or 2?), skipping subcats that don't say "company" or "companies"
 *    - For each matching "List_of_companies_of_X" page, parse companies and store in a JSON for that X
 *
 * Adjust `MAX_DEPTH` to control how far you want to drill down. 
 * If you want more companies (like in the US), you can set it bigger, but risk wandering into weird subcats.
 */
export async function scrapeAllCountriesNoLimit() {
  const startCategory = "https://en.wikipedia.org/wiki/Category:Lists_of_companies_by_country";

  const visitedCategories = new Set();
  const visitedArticles = new Set();

  const folderPath = path.join(process.cwd(), "countries");
  if (!fs.existsSync(folderPath)) fs.mkdirSync(folderPath, { recursive: true });

  // We'll pick a maxDepth. 2 or 3 is typical. 
  // If you want more, set it higher. But watch out for irrelevant expansions.
  const MAX_DEPTH = 100;

  // BFS for categories with depth limit
  async function recurseCat(catUrl, depth) {
    if (visitedCategories.has(catUrl)) return;
    visitedCategories.add(catUrl);

    const { subcategories, articles } = await scrapeCategoryNoLimit(catUrl, new Set(), depth, MAX_DEPTH);

    for (const subcat of subcategories) {
      if (!visitedCategories.has(subcat)) {
        await recurseCat(subcat, depth + 1);
      }
    }

    for (const articleUrl of articles) {
      if (visitedArticles.has(articleUrl)) continue;
      visitedArticles.add(articleUrl);

      // Must match "List_of_companies_of_" or "List_of_companies_in_"
      if (!/List_of_companies_of_|List_of_companies_in_/i.test(articleUrl)) {
        continue;
      }

      const companies = await scrapeCompaniesFromPage(articleUrl);
      const countryName = parseCountryFromUrl(articleUrl);
      const filePath = path.join(folderPath, countryName + ".json");

      let existing = [];
      if (fs.existsSync(filePath)) {
        try {
          existing = JSON.parse(fs.readFileSync(filePath, "utf8"));
          if (!Array.isArray(existing)) existing = [];
        } catch {}
      }

      const merged = new Set([...existing, ...companies]);
      const mergedArr = Array.from(merged);
      fs.writeFileSync(filePath, JSON.stringify(mergedArr, null, 2));
      console.log(`Scraped ${companies.length} comps from ${articleUrl}, wrote => ${filePath} (now has ${mergedArr.length} total)`);
    }
  }

  console.log(`Starting from top-level category: ${startCategory}`);
  await recurseCat(startCategory, 0);
  console.log("Finished all scraping with filters + depth limit!");
}
