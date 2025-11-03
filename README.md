# Calorie Counter — AI-Assisted Nutrition Tracker

Calorie Counter is a Ruby on Rails web application that allows users to log meals, calculate personalized macro targets, and stay accountable across devices. It supports Google OAuth sign-in, onboarding surveys that tailor goals, AI-powered photo analysis for food entries, and an accessible dashboard that works even when JavaScript is disabled.

It’s fully tested with RSpec and Cucumber, styled with Rubocop, and includes GitHub Actions CI/CD that deploys automatically to Heroku after merging to main.

---

## Useful URLs

| Resource | Link / Notes |
| --- | --- |
| Heroku Dashboard | TBD (deployment in progress) |
| GitHub Actions | https://github.com/tamu-edu-students/CSCE606-Group2-Project2/actions |
| GitHub Projects Dashboard | https://github.com/orgs/tamu-edu-students/projects (Project 2 board) |
| Burn up chart | https://github.com/orgs/tamu-edu-students/projects (Insights available once milestones begin) |
| Slack Group (Scrum) | `#project2-checkins` (link shared in the course workspace) |
| Daily Scrum | 9PM–9:30PM on Zoom (Slack workflow posts reminder with meeting link) |

---

## Features

- Google OAuth-based login with OmniAuth (test mode support for automated suites)
- Complete onboarding survey to compute calorie and macro goals with metric/imperial input
- Create, edit, and delete food logs with optional photo uploads stored via Active Storage
- Trigger AI-powered nutrition analysis using OpenAI Vision when macro fields are blank
- View daily dashboard summarizing remaining calories, macro balance, and recent meals
- Sort food logs by date or macronutrients with grouping by day
- Manual logging paths that work with or without JavaScript enabled
- RSpec and Cucumber tests for backend calculations and end-to-end flows
- RuboCop, Brakeman, and Importmap audit checks enforced through GitHub Actions
- CI/CD pipeline that deploys automatically to Heroku once all checks pass

---

## Tech Stack

| Category | Technology |
| --- | --- |
| Framework | Ruby on Rails 8.1 |
| Language | Ruby 3.4.5 (see `.ruby-version`) |
| Database | SQLite (Dev/Test), PostgreSQL (Heroku) |
| Authentication | Google OAuth via OmniAuth (`omniauth-google-oauth2`) |
| Testing | RSpec, Cucumber, SimpleCov |
| Linting | RuboCop Rails Omakase, Brakeman, Importmap audit |
| CI/CD | GitHub Actions (`.github/workflows/ci.yml`) |
| File Storage | Active Storage (local disk in dev/test) |
| AI Integration | OpenAI Vision via `ruby-openai` |
| Deployment | Heroku |
| Sprint Planning / Story Board | GitHub Projects |

---

## Getting Started — From Zero to Deployed

### 1️⃣ Prerequisites

Make sure you have the following installed:

| Tool | Install Command |
| --- | --- |
| Ruby | `rbenv install 3.4.5` |
| Bundler | `gem install bundler` |
| SQLite3 (for local development) | `sudo apt-get install sqlite3 libsqlite3-dev` (Linux) or `brew install sqlite3` (Mac) |
| Git | `sudo apt install git` |
| Heroku CLI | Install guide |

### 2️⃣ Clone the Repository

```bash
git clone https://github.com/tamu-edu-students/CSCE606-Group2-Project2.git
cd CSCE606-Group2-Project2
```

### 3️⃣ Install Dependencies

```bash
bundle install
```

### 4️⃣ Setup the Database

```bash
# Create, migrate, and prepare test DB
rails db:migrate
rails db:prepare

# (Optional) Seed with sample data (none by default; add entries before running)
rails db:seed
```

### 5️⃣ Run Locally

```bash
rails server
```

Visit: http://localhost:3000  
Sign in using the Google OAuth button; in test mode the app uses OmniAuth's fake provider credentials.

**Seeded Users**

| Email | Password |
| --- | --- |
| Use Google OAuth test account | Handled by provider (no local password) |

### 6️⃣ Run the Test Suite

This project uses both RSpec (for unit testing) and Cucumber (for feature/BDD testing).

```bash
# RSpec (unit & request tests)
bundle exec rspec

# Cucumber (feature tests)
bundle exec cucumber

# View Coverage Report (coverage is generated after test runs)
open coverage/index.html
```

### 7️⃣ Setup Heroku Deployment (CD)

**Step 1: Create a Heroku App**

```bash
heroku login
heroku create <your-app-name>  # ex: heroku create calorie-counter-group2
```

**Step 2: Add PostgreSQL Add-on**

```bash
heroku addons:create heroku-postgresql:mini --app <your-app-name>
# ex: heroku addons:create heroku-postgresql:mini --app calorie-counter-group2
```

Run `git remote` to confirm the new `heroku` remote, and `git remote show heroku` to verify the target URL.

**Step 3: Set GitHub Secrets**

Add the following under GitHub → Settings → Secrets and Variables → Actions:

| Secret | Description |
| --- | --- |
| `HEROKU_API_KEY` | Your Heroku API key (`heroku auth:token`) |
| `HEROKU_APP_NAME` | Your Heroku app name |
| `HEROKU_EMAIL` | Your Heroku account email |
| `GOOGLE_CLIENT_ID` | OAuth client ID used by the Rails app |
| `GOOGLE_CLIENT_SECRET` | OAuth client secret |
| `OPENAI_API_KEY` | Optional - API key for vision-based nutrition analysis |

**Step 4: Database Setup and Deployment**

```bash
# Run on first deploy
heroku run bin/rails db:migrate --app <your-app-name>
heroku run bin/rails db:seed --app <your-app-name>
```

These steps are added as worker processes in the Procfile to avoid manual repetition. Every merge to `main` triggers deployment through `.github/workflows/ci.yml`. Track progress under the repository Actions tab; the deploy job only runs after all checks pass.

**Manual Deployment (if not using GitHub Actions)**

```bash
heroku run bin/rails db:migrate --app <your-app-name>
heroku run bin/rails db:seed --app <your-app-name>
git push heroku main
heroku open
```

---

## CI/CD Pipeline Summary

| Stage | What it Does |
| --- | --- |
| `scan_ruby` | Runs Brakeman for Rails security issues |
| `scan_js` | Audits JS dependencies |
| `lint` | Runs RuboCop for code style |
| `test` | Runs RSpec + Cucumber (with coverage artifact upload) |
| `deploy` | Deploys to Heroku automatically after merge to main once all tests pass |

---

## Useful Commands

| Task | Command |
| --- | --- |
| Start server | `rails server` |
| Run RSpec tests | `bundle exec rspec` |
| Run single RSpec test | `bundle exec rspec spec/models/user_spec.rb` |
| Run Cucumber tests | `bundle exec cucumber` |
| Run single Cucumber scenario | `bundle exec cucumber features/onboarding.feature` |
| Check test coverage | `open coverage/index.html` |
| Check latest Heroku logs | `heroku logs --tail` |
| Reset local database | `rails db:drop db:create db:migrate` |

---

## Project Diagrams

- **Database Schema Design (ER):** `Diagrams/DBSchema.drawio.png`
- **System Diagram:** `Diagrams/System.drawio.png`
- **Architecture Diagram:** `Diagrams/Architecture.drawio.png`
- **Class Diagram:** `Diagrams/Class.drawio.png`

---

## User Guide — Calorie Counter

Calorie Counter is designed to make nutrition tracking simple, guided, and resilient—with photo analysis, macro dashboards, and onboarding that adapts to each user, all built on Ruby on Rails.

### Getting Started

**Access the App**  
Visit your deployed app once the Heroku pipeline completes (ex: https://calorie-counter-group2.herokuapp.com/)

**Sign Up / Log In**

- Click **Sign in with Google** to authenticate via OAuth.
- In test mode, OmniAuth provides a fake Google profile so developers can log in without external credentials.

### Dashboard Overview

After signing in, the dashboard highlights:

- Today’s remaining calories and macros
- A breakdown of recent meals logged
- Quick links to add a new food entry or review the onboarding survey
- A flash banner if you are over your calorie goal

### Creating and Editing Food Logs

1. Click **Log a meal** from the dashboard.
2. Provide a food name and either:
   - Enter calories, protein, fats, and carbs manually, or
   - Upload a photo so the AI service can suggest values.
3. Click **Create** to save; the log appears grouped by date.
4. To edit, open a food entry, adjust values (or upload a new photo), then click **Update**.

> Tip: Logs are sorted by most recent by default. Use the sort picker to switch between date and macro-based ordering.

### AI Photo Analysis

1. Attach an image while creating or editing a log.
2. Leave macro fields blank to trigger OpenAI Vision.
3. Submit the form and review suggested macros; adjust before saving if needed.
4. If the AI call fails or the key is missing, a friendly error appears and manual values are preserved.

### Managing Your Account

- **Update Goals:** Go to Profile → Update goals, adjust weight/activity/goal, and submit to recalculate macros instantly.
- **Delete Account:** Choose Delete Account → Confirm to permanently remove your account and associated logs.

We designed Calorie Counter to respect user control—personal data is scrubbed during deletion, and AI suggestions never persist without explicit confirmation.

---

## Goal Adjustment Rules

| Action | User | AI Assistant |
| --- | --- | --- |
| Create log | ✅ | Provides optional suggestions |
| Edit log | ✅ | Offers recalculated estimates |
| Delete log | ✅ | ❌ |
| Recalculate daily goals | ✅ | Not applicable |
| Trigger photo analysis | ✅ | ✅ (requires API key) |

---

## Tips for Best Use

- Keep your onboarding info current so macro targets stay accurate.
- Upload clear, well-lit photos for best AI results.
- Review AI-suggested macros before saving.
- Log meals shortly after eating for precise day totals.
- Store your OpenAI key in `.env` during development and Heroku config vars in production.

---

## Sample Logins (OmniAuth Test Mode)

If you run in development without real Google credentials, OmniAuth provides:

| Name | Email | Password |
| --- | --- | --- |
| Test User | tester@example.com | Handled by provider |
| Second Tester | second@example.com | Handled by provider |

These accounts exist only in local/test environments and are not persisted unless you save them.

---

## Troubleshooting

| Problem | Cause | Solution |
| --- | --- | --- |
| Cannot sign in | `GOOGLE_CLIENT_ID`/`SECRET` missing | Export both values or enable OmniAuth test mode |
| AI analysis fails | `OPENAI_API_KEY` not set or request timed out | Check logs and ensure API key is configured |
| No coverage report after tests | SimpleCov not required | Require SimpleCov before specs or rerun with `SIMPLECOV_MINIMUM` |
| Heroku deploy fails | Secrets missing in GitHub Actions | Add `HEROKU_*` and Google credentials to repository secrets |
| Macros don’t update after profile change | Onboarding form submitted without recalculation | Check flash message and revisit Update goals |
| Local server crashes on photo upload | ImageMagick missing (for variants) | Install `image_processing` dependencies or remove variant usage |

---

## Architecture Decision Records (ADRs)

### ADR 1 – Authentication with Google OAuth

- **Status:** Accepted  
- **Date:** 09-15-2024

**Context**  
We needed a low-friction way for students to authenticate without managing passwords, while aligning with university SSO expectations and project rubric requirements.

**Decision**  
Use OmniAuth with the `google_oauth2` strategy, enabling test mode in non-production environments to keep specs and Cucumber scenarios deterministic.

**Consequences**  
- Advantage: Provides familiar, secure sign-in with minimal UI.  
- Advantage: Test mode keeps automated suites independent of third-party services.  
- Downside: Requires Google credentials or test mode configuration before demos.

### ADR 2 – Macro Goal Calculation Service

- **Status:** Accepted  
- **Date:** 09-21-2024

**Context**  
During onboarding, users supply height, weight, activity level, and goal. The logic must support metric/imperial inputs and recalculations when preferences change.

**Decision**  
Isolate data normalization in `MeasurementParamsNormalizer` and encapsulate calculations inside `User#calculate_goals!` so the same entry point serves onboarding, profile edits, and background recalculations.

**Consequences**  
- Advantage: Reusable service keeps controllers slim and testable.  
- Advantage: Centralizes validation and safe ranges for macros.  
- Advantage: Supports both manual overrides and auto-calculated goals.  
- Downside: Additional callbacks add complexity when debugging goal updates.

### ADR 3 – Vision AI for Macro Suggestions

- **Status:** Accepted  
- **Date:** 09-28-2024

**Context**  
Students requested a fast path to log meals from photos without typing macros. We evaluated client-side OCR vs. server-side AI.

**Decision**  
Integrate OpenAI Vision through `NutritionAnalysis::VisionClient`, generating suggestions only when macro fields are blank and the user provides a photo.

**Consequences**  
- Advantage: Produces context-rich macro estimates with minimal UI changes.  
- Advantage: Fails gracefully when API keys are absent or calls timeout.  
- Downside: Adds latency (~1-2s) and depends on an external paid API.

### ADR 4 – Progressive Enhancement for No-JS Flow

- **Status:** Accepted  
- **Date:** 10-02-2024

**Context**  
Accessibility requirements and the grading rubric mandate full functionality without JavaScript, yet we still want responsive UX for modern browsers.

**Decision**  
Build forms with Rails helpers (`form_with local: true`) and rely on Turbo only for optional enhancements, ensuring every flow (onboarding, logging, dashboards) posts traditional requests.

**Consequences**  
- Advantage: Screen readers and no-JS users get identical flows.  
- Advantage: Server-rendered pages simplify testing and reduce flakes.  
- Downside: Some interactions (sorting) require full-page reloads instead of instant updates.

---

## Postmortem

### Issue 1: OAuth Redirect URI Mismatch

- **Date:** 09-24-2024  
- **Status:** Resolved  
- **Related ADR:** ADR 1 – Authentication with Google OAuth  
- **Affected Areas:** Login flow, onboarding redirect

**Summary**  
During our first Heroku deployment the Google console had not been updated with the production callback URL, causing sign-ins to fail with a 400 error.

**Impact**  
- User Experience: All users saw "Authentication failed" after Google redirected back.  
- System Integrity: No data loss, but sessions were never established so dashboards were inaccessible.  
- Business Impact: High—blocked every login attempt in production.

**Root Cause**  
The OmniAuth initializer relied on default callback URLs, but the Google Cloud project only whitelisted localhost addresses. Heroku's hostname triggered a mismatch.

**Resolution**  
Added the Heroku URL to the OAuth consent screen, updated the initializer to read `ENV["DEFAULT_HOST"]`, and configured `config.action_controller.default_url_options`. Rolled a hotfix deploy after confirming sign-in via smoke tests.

**Implementation Highlights**

- Environment variable `DEFAULT_HOST` documented in `.env.example`.  
- Updated smoke test script to hit `/auth/google_oauth2` on staging before release.  
- Added runbook entry under Debug Pointers for quick verification.

### Issue 2: Nutrition Analysis Timeouts

- **Date:** 10-03-2024  
- **Status:** Resolved  
- **Affected Areas:** Food log creation, AI service integration

**Summary**  
API calls to OpenAI occasionally exceeded 10 seconds, freezing the create/update flow and confusing users with blank pages.

**Impact**  
- User Experience: Food log forms appeared to hang, and users sometimes resubmitted creating duplicates.  
- System Integrity: Background threads piled up, increasing memory usage when timeouts stacked.  
- Business Impact: Medium—manual entry still worked, but the flagship AI feature was unreliable.

**Root Cause**  
We instantiated the OpenAI client per request without setting a timeout, so slow responses blocked Puma workers.

**Resolution**  
Introduced a connection-level timeout, moved client instantiation to a memoized helper, and added rescue logic with a friendly flash alert.

**Implementation Highlights**

- `NutritionAnalysis::VisionClient` now sets `request_timeout: 8` seconds.  
- Controller handles failure states and re-renders with the uploaded image.  
- Cucumber scenario covers the error path to avoid regressions.

---

## Debug Pointers

| Issue / Area | Tried Solutions | Final Working Fix / Recommendation |
| --- | --- | --- |
| Google OAuth failing in development | Restarted server, cleared cookies | Set `OmniAuth.config.test_mode = true` or export valid `GOOGLE_*` secrets |
| Calories not recalculating after onboarding | Reloaded browser | Clear cached params and ensure `MeasurementParamsNormalizer` receives `measurement_system` |
| AI suggestions too high compared to manual entries | Tweaked goal multipliers | Add guardrails and allow users to edit macros before saving |
| Image uploads breaking specs | Disabled attachment tests | Use `ActiveStorage::Blob.open(tempfile)` helper within specs |
| CI deploy job pushing stale code | Pushed again from local | Ensure `git fetch origin main:main` step remains in workflow before pushing to Heroku |

---

## Debugging Common Issues

| Problem | Likely Cause | Fix |
| --- | --- | --- |
| `bundle install` fails | Ruby version mismatch | `rbenv local 3.4.5 && bundle install` |
| `rails server` won’t start | Missing `GOOGLE_CLIENT_ID`/`SECRET` | Set env vars or enable OmniAuth test mode |
| RSpec tests fail | Database not prepared | `RAILS_ENV=test rails db:prepare` |
| Cucumber hangs on photo scenario | Chromedriver/ImageMagick missing | Install required system deps or skip JS tags |
| Heroku deploy fails | `OPENAI_API_KEY` not set on Heroku | Add config var or disable AI feature via ENV flag |
| “ActiveRecord::PendingMigrationError” when starting server | Local migrations haven’t been applied | `rails db:migrate` |

---

## Summary

Calorie Counter helps you:

- Track calories and macros with AI-assisted workflows
- Personalize nutrition goals through guided onboarding
- Stay accessible across devices—even without JavaScript
- Deploy confidently with automated tests and CI/CD

---

## Team Members

- Cameron Yoffe
- Khussal Pradhan
- Yifei Wang

---

_“Fuel smart decisions with every log.”_
