# Calorie Counter — AI-Assisted Nutrition Tracker

Calorie Counter is a Ruby on Rails 8 application that helps users monitor calorie and macro targets, powered by Google OAuth sign-in and optional OpenAI Vision analysis for food photos. Every workflow degrades gracefully without JavaScript, so users can always enter meals and review dashboards regardless of device or accessibility settings. A full automated test suite and security scans run in CI to keep the experience reliable.

---

## Key Capabilities
- Google single sign-on via OmniAuth with a test-mode fallback for automated suites.
- Onboarding survey that captures biometrics, computes personalized macro targets, and updates them as preferences change.
- Food logging with optional image upload routed to the OpenAI Vision API; manual entry remains available if AI calls fail or credentials are missing.
- Daily dashboard that surfaces remaining calories/macros, recent meals, and history filters.
- Accessibility-first HTML forms that work with or without JavaScript and support screen readers.
- CI workflow enforcing security scans, style checks, and 90% combined coverage across RSpec and Cucumber.

---

## Tech Stack

| Category | Details |
| --- | --- |
| Framework | Ruby on Rails 8.1 (Ruby 3.4.5) |
| Frontend | Turbo, Stimulus, Importmap, Propshaft |
| Authentication | OmniAuth Google OAuth 2.0 |
| Data Store | SQLite (development/test), PostgreSQL (production) |
| File Storage | Active Storage (local disk in development) |
| Background & caching | Solid Queue, Solid Cache, Thruster + Puma |
| AI Integration | OpenAI Vision via `ruby-openai` |
| Testing | RSpec, Cucumber, SimpleCov |
| Quality & Security | RuboCop Rails Omakase, Brakeman, Importmap audit |
| CI/CD | GitHub Actions workflow at `.github/workflows/ci.yml` |

---

## Architecture & Documentation

- High-level diagrams live in `Diagrams/`:
  - ![Architecture Diagram](Diagrams/Architecture.drawio.png)
  - ![System Diagram](Diagrams/System.drawio.png)
  - ![Database Schema](Diagrams/DBSchema.drawio.png)
  - ![Class Diagram](Diagrams/Class.drawio.png)
- Production-focused container image defined in `Dockerfile` (build with `docker build -t calorie-counter .`).
- Domain services for AI analysis located under `app/services/nutrition_analysis/`.

---

## Getting Started

### 1. Prerequisites

| Tool | Version / Notes |
| --- | --- |
| Ruby | 3.4.5 (match `.ruby-version`; install via `rbenv install 3.4.5`) |
| Bundler | ≥ 2.6 (`gem install bundler`) |
| SQLite3 | Required for local development/test (`brew install sqlite` or `sudo apt-get install sqlite3 libsqlite3-dev`) |
| PostgreSQL | Required for production deployments |
| Git | `sudo apt-get install git` or `brew install git` |

### 2. Clone the repository

```bash
git clone https://github.com/tamu-edu-students/CSCE606-Group2-Project2.git
cd CSCE606-Group2-Project2
```

### 3. Configure environment variables

Create `.env` (or export variables in your shell) and keep it out of version control:

```bash
cat <<'EOF' > .env
export GOOGLE_CLIENT_ID=your-google-client-id
export GOOGLE_CLIENT_SECRET=your-google-client-secret
# Optional: enable AI photo analysis
export OPENAI_API_KEY=sk-your-openai-key
export OPENAI_VISION_MODEL=gpt-4o-mini
EOF
```

Load the variables before running Rails:

```bash
source .env
```

| Variable | Required | Description |
| --- | --- | --- |
| `GOOGLE_CLIENT_ID` | Yes (dev/prod) | OAuth client ID created in the Google Cloud Console. |
| `GOOGLE_CLIENT_SECRET` | Yes (dev/prod) | OAuth client secret paired with the client ID. |
| `OPENAI_API_KEY` | Optional | Enables automatic nutrition analysis for uploaded photos. Without it, users still log meals manually. |
| `OPENAI_VISION_MODEL` | Optional | Overrides the default `gpt-4o-mini` model. |

The project ships with `dotenv-rails`, so variables in `.env`, `.env.development`, or `.env.test` are loaded automatically.

### 4. Install Ruby dependencies

```bash
bundle install
```

### 5. Prepare the database

```bash
bin/rails db:prepare
```

This command creates, migrates, and seeds (if defined) both the development and test databases. Active Storage tables are included.

### 6. Run the application locally

```bash
bin/rails server
```

Visit `http://localhost:3000`, sign in with Google, and complete the onboarding flow. In the test environment, OmniAuth switches to test mode automatically, so integration specs run without hitting Google.

### 7. Execute the test suite and quality checks

```bash
# RSpec request/unit/system tests
bin/rails spec

# Cucumber feature tests
bin/rails cucumber

# Enforce 90% minimum coverage across suites
SIMPLECOV_MINIMUM=90 bin/rails spec
SIMPLECOV_MINIMUM=90 bin/rails cucumber

# Static analysis
bin/brakeman
bin/rubocop
bin/importmap audit
```

Coverage reports are written to `coverage/` and merged automatically when both suites run.

---

## Continuous Integration

GitHub Actions workflow (`.github/workflows/ci.yml`) runs on every push and pull request:
1. Brakeman security scan and import map audit.
2. RuboCop linting (Omakase rules).
3. RSpec and Cucumber suites with a 90% minimum coverage gate.
4. Archive coverage artifacts for later inspection.

Branch protection is easiest when local checks pass before opening a pull request.

---

## Deployment Notes

- The application is 12-factor ready: supply the same environment variables used locally, along with `RAILS_MASTER_KEY` from `config/master.key`.
- The provided `Dockerfile` builds a production image that precompiles assets, installs gems, and runs the app via Thruster/Puma.
- For platforms like Heroku or Render, ensure PostgreSQL is provisioned and run `bin/rails db:migrate` after each deploy.
- Active Storage defaults to local disk; configure an S3-compatible service in production via `config/storage.yml`.

---

## Troubleshooting & Developer Tips

| Symptom | Likely Cause | Recommended Fix |
| --- | --- | --- |
| `bundle install` fails | Ruby version mismatch | Align with `.ruby-version` (`rbenv local 3.4.5 && bundle install`). |
| Google sign-in button is hidden | Missing OAuth credentials | Export `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`, then restart the server. |
| Photo analysis returns an error banner | No OpenAI credentials or API failure | Set `OPENAI_API_KEY`, confirm the model name, or retry with manual macro entry. |
| `ActiveRecord::PendingMigrationError` on startup | Database not prepared | Run `bin/rails db:prepare` (and include `RAILS_ENV=test` for the test database). |
| Cucumber scenarios fail to sign in | Test env not loading OmniAuth test mode | Ensure `Rails.env.test?` is true (use `bin/rails cucumber`) and do not override `OmniAuth.config.test_mode`. |
| GitHub Actions fails coverage gate | Suites not run with `SIMPLECOV_MINIMUM` | Execute both RSpec and Cucumber locally with the environment variable set to mirror CI. |

---

Calorie Counter is maintained by CSCE 606 Group 2. Issues and enhancements are welcomed via pull requests—run the local checks above before submitting.
