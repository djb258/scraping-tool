// scrapeCompanyContacts.js
require('dotenv').config();

const { getPendingCompanies } = require('./modules/getPendingCompanies');
const { runApifyScrape } = require('./modules/runApifyScrape');
const { pollApifyRun } = require('./modules/pollApifyRun');
const { fetchApifyDataset } = require('./modules/fetchApifyDataset');
const { filterContactsByTitle } = require('./modules/filterContactsByTitle');
const { writeResults } = require('./modules/writeResults');
const { markCompanyStatus } = require('./modules/markCompanyStatus');

const dryRun = process.env.DRY_RUN === 'false' ? false : true;

async function main() {
  console.log(`[START] Cold Outreach Scraper | dryRun=${dryRun}`);
  try {
    const companies = await getPendingCompanies();
    console.log(`[INFO] Fetched ${companies.length} pending companies.`);
    for (const company of companies) {
      try {
        console.log(`[INFO] Scraping company: ${company.id} | ${company.apollo_url}`);
        const runId = await runApifyScrape(company);
        const datasetId = await pollApifyRun(runId);
        const contacts = await fetchApifyDataset(datasetId);
        const filtered = filterContactsByTitle(contacts);
        await writeResults(filtered, dryRun ? 'firebase' : 'neon');
        await markCompanyStatus(company.id, 'COMPLETE');
        console.log(`[SUCCESS] Company ${company.id} processed.`);
      } catch (err) {
        console.error(`[ERROR] Company ${company.id}:`, err);
        await markCompanyStatus(company.id, 'ERROR');
      }
    }
  } catch (err) {
    console.error('[FATAL] Error in main loop:', err);
  }
  console.log('[END] Scraper run complete.');
}

main(); 