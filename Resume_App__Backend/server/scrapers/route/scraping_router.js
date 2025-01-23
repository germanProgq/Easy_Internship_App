// routes/scraping_router.js

import express from "express";
import cron from "node-cron";

import { scrapeAllCountriesNoLimit } from "../service/companies_by_country.js";
import { processCountries } from "../domain_by_company.js";

const router = express.Router();

/**
 * Utility function that triggers everything (scraping + processing).
 */
const triggerAllScraping = async () => {
  await scrapeAllCountriesNoLimit();
  await processCountries();
};

/**
 * Cron job to run daily at 2 AM.
 * It calls the same utility function so the logic remains DRY.
 */
cron.schedule("0 2 * * *", async () => {
  console.log("[CRON] Starting scheduled scraping of all countries...");
  try {
    await triggerAllScraping();
    console.log("[CRON] Finished scheduled scraping job.");
  } catch (err) {
    console.error("[CRON] Error in scheduled scraping:", err);
  }
});

/**
 * GET /scraping/trigger
 * Performs only the scraping of all countries (no domain processing).
 */
router.get("/trigger", async (req, res) => {
  try {
    await scrapeAllCountriesNoLimit();
    res.json("Fetched all countries' companies successfully (scraping only).");
  } catch (err) {
    console.error("Error in /scraping/trigger: ", err);
    res.status(500).json({ error: "Failed to fetch or parse category" });
  }
});

/**
 * GET /search-domains
 * Performs only domain processing for all countries (no new scraping).
 */
router.get("/search-domains", async (req, res) => {
  try {
    await processCountries();
    res.json({
      message: "All countries processed successfully for domain searching.",
    });
  } catch (err) {
    console.error("Error in /search-domains: ", err);
    res.status(500).json({
      error: "Failed to complete domain scraping job",
    });
  }
});

/**
 * GET /scraping/trigger-all
 * Invokes both scraping and domain processing in one go.
 */
router.get("/trigger-all", async (req, res) => {
  try {
    await triggerAllScraping();
    res.json("Successfully triggered scraping and domain searching!");
  } catch (err) {
    console.error("Error in /trigger-all:", err);
    res.status(500).json({ error: "Failed to complete scraping and domain searching." });
  }
});

export default router;
