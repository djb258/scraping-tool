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

## ORBT Log Prefix System
All logs are prefixed for easy troubleshooting:
- `[O]` = Observability (step, info, trace)
- `[R]` = Resilience (success, error, retry)
- `[B]` = Boundaries (config, limits, dry-run)
- `[T]` = Testability (test output, validation)

**Use these prefixes to quickly identify where an issue occurred and which module or concern it relates to.**

## Troubleshooting & Helper Agent Guide

### 1. Database Connection Issues
- **Error:** `Database connection string provided to neon() is not a valid URL`
  - **Solution:** Make sure `NEON_DATABASE_URL` starts with `postgresql://` and has no extra quotes or prefixes.
- **Error:** `relation "marketing_company_intake" does not exist`
  - **Solution:** Ensure the table exists in your Neon database. Create it if needed.

### 2. Apify API Issues
- **Error:** `User was not found or authentication token is not valid`
  - **Solution:** Double-check your `APIFY_API_KEY` and make sure it matches the account that owns the dataset/task.
- **Error:** `Dataset was not found`
  - **Solution:** Verify the dataset ID exists and is accessible with your API key.

### 3. Environment Variables
- **Check variables locally:**  
  Run `node -e "console.log(process.env)"` or use the provided `testEnv.js` script.
- **On Render:**  
  Go to the Render dashboard → Environment → check/edit variables.

### 4. Logs & Debugging
- **Local logs:**  
  All steps are logged to the console with ORBT-aligned messages.
- **Render logs:**  
  View logs in the Render dashboard under the "Logs" tab.

### 5. Test Scripts
- Use `testGetPendingCompanies.js` to test Neon DB connection.
- Use `testFetchApifyDataset.js` to test Apify dataset access.

### 6. Redeploying/Restarting
- After changing environment variables on Render, click "Manual Deploy" or "Restart" to apply changes.

### 7. Updating the Repo
- Never commit `.env` or `cold.env` files.
- Use `git pull` to get the latest changes.
- Use `git push` to update the remote repo.

---

**If you encounter an error not listed here, check the logs for details and review the code comments for each module. Use the ORBT log prefix to quickly identify the source and type of issue.** 