# Cold Outreach Scraper Agent

This repository contains a production-safe, ORBT-compliant Node.js agent for scraping company contacts using Apify and Neon. The agent is modular, supports dry-run mode, and is ready for integration with Firebase and BigQuery.

## What this repo is for
- **Automated cold outreach scraping**: Pulls companies from a Neon Postgres table, scrapes contacts from Apify, and (optionally) writes results to Firebase/BigQuery.
- **ORBT Doctrine**: Built for Observability, Resilience, Boundaries, and Testability.
- **Production-ready**: Modular, environment-variable driven, and safe for cloud deployment.

## Render Deployment
- **Live Render endpoint:** [https://scraping-tool-e1vt.onrender.com](https://scraping-tool-e1vt.onrender.com)
- Note: The current deployment is a background script/agent, not a web server. If you want a web API, add an Express server and listen on `process.env.PORT`.

## Usage
- Configure environment variables (`NEON_DATABASE_URL`, `APIFY_API_KEY`, `APIFY_TASK_ID`, `DRY_RUN`, etc.) in your `.env` or Render dashboard.
- Run the agent with:
  ```sh
  node scrapeCompanyContacts.js
  ```
- For web API usage, see the README section on Express integration.

## Modules
- `getPendingCompanies`: Fetches companies to scrape from Neon.
- `runApifyScrape`: Triggers Apify Apollo scraper.
- `pollApifyRun`: (Stub) Polls Apify for run completion.
- `fetchApifyDataset`: Fetches contacts from Apify dataset.
- `filterContactsByTitle`: (Stub) Filters contacts for target roles.
- `writeResults`: (Stub) Writes results to Firebase/Neon.
- `markCompanyStatus`: (Stub) Updates company scrape status in Neon.

## Security
- **Never commit secrets** (`.env`, `cold.env`) to the repo. Use Render’s environment variable dashboard for production secrets.

---

For more details, see the code and comments in each module. 