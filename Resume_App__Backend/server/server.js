// server.js
import express from "express";
import mainRouter from './routers/main.js'
import scrapingRouter from "./scrapers/route/scraping_router.js";
import 'dotenv/config'

const app = express();
const PORT = process.env.PORT || 3000;

// Mount the two routers
//  1) /api/... => for user-facing scraping queries
app.use("/api", mainRouter);

//  2) /scraping/... => for admin or scheduled scraping
app.use("/scraping", scrapingRouter);

app.listen(PORT, () => {
  console.log(`Server listening on http://localhost:${PORT}`);
});
