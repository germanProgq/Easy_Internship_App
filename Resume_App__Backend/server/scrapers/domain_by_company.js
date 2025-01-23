import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import { findCompanyDomain } from './service/scrape_domains.js';

// Because we may be running as an ES Module, we need __dirname:
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Main driver function:
 *  1) Reads all JSON files in ./countries
 *  2) For each file, parses array of company names
 *  3) Runs findCompanyDomain(...) to fetch domain
 *  4) Saves an array of { name, domain } objects back to the file
 */
export async function processCountries() {
  const countriesDir = path.join(__dirname, 'countries');

  // Read all files in the `countries` folder
  const files = fs.readdirSync(countriesDir);

  for (const file of files) {
    // Only handle .json files
    if (path.extname(file).toLowerCase() === '.json') {
      const filePath = path.join(countriesDir, file);

      // 1) Read the JSON array (company names)
      const jsonStr = fs.readFileSync(filePath, 'utf-8');
      let companies;
      try {
        companies = JSON.parse(jsonStr);
        if (!Array.isArray(companies)) {
          console.warn(`File "${file}" does not contain an array. Skipping.`);
          continue;
        }
      } catch (err) {
        console.error(`Failed to parse "${file}":`, err);
        continue;
      }

      console.log(`Processing file "${file}" with ${companies.length} entries...`);

      // 2) For each company name, find domain and build { name, domain } objects
      const updatedData = [];
      for (const companyName of companies) {
        // Run the domain finder for each company
        console.log(`  Looking up: "${companyName}"...`);
        let domain = null;
        try {
          domain = await findCompanyDomain(companyName);
        } catch (err) {
          console.error(`    Error finding domain for "${companyName}":`, err);
        }
        updatedData.push({
          name: companyName,
          domain: domain || null
        });
      }

      // 3) Write the updated data back to the same file
      try {
        fs.writeFileSync(filePath, JSON.stringify(updatedData, null, 2), 'utf-8');
        console.log(`File "${file}" updated successfully!\n`);
      } catch (err) {
        console.error(`Failed to write updated data to "${file}":`, err);
      }
    }
  }
}

// For direct invocation: `node processCountries.js`
processCountries().then(() => {
  console.log('All done!');
}).catch((err) => {
  console.error('Unexpected error:', err);
});
