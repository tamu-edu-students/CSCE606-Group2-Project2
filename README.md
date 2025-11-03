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
| `GOOGLE_CLIENT_ID` | yes (production/dev) | OAuth 2.0 client ID for Google sign-in. |
| `GOOGLE_CLIENT_SECRET` | yes (production/dev) | OAuth client secret. |
| `OPENAI_API_KEY` | optional | Enables GPT-based nutrition analysis for uploaded food photos. Without it, users can still enter macros manually. |
| `OPENAI_VISION_MODEL` | optional | Override the default `gpt-4o-mini` vision model. |

Test and development also respect `.env.test` / `.env.development` if you use `dotenv-rails` (not required).

### Running Tests & Quality Checks
- **RSpec unit/integration tests:** `bin/rails spec`
- **Cucumber feature tests:** `bin/rails cucumber`
- **All tests with coverage (90% minimum):**
  ```bash
  SIMPLECOV_MINIMUM=90 bin/rails spec
  SIMPLECOV_MINIMUM=90 bin/rails cucumber
  ```
  Coverage reports are written to `coverage/` and merged automatically.

- **Static analysis:**
  ```bash
  bin/brakeman           # security scan
  bin/rubocop            # style & lint
  bin/importmap audit    # JS dependency audit
  ```

### Working Without JavaScript
Forms use standard HTML controls (`button_to`, `form_with` with `local: true`) so Google login, onboarding, and food logging remain functional when JS is disabled. Image uploads and AI analysis also work entirely server side.

### GPT Nutrition Analysis
`NutritionAnalysis::VisionClient` sends uploaded photos to OpenAI's vision endpoint. When `OPENAI_API_KEY` is absent or the API call fails, users receive actionable feedback and can still log meals by entering macros manually.

### Continuous Integration
`.github/workflows/ci.yml` runs on every push/PR:
1. Security scans (Brakeman) and import map audit.
2. Rubocop linting.
3. RSpec + Cucumber, enforcing a ≥90% merged coverage threshold and uploading the HTML report as an artifact.

### Additional Tips
- OmniAuth automatically enters test mode in the test environment, so feature specs can sign in without real Google credentials.
- Image attachments use Active Storage's disk service locally (`storage/`). Clean up with `bin/rails active_storage:install` migrations already provided.
- To exercise the AI flow locally, set `OPENAI_API_KEY` and restart the server. Otherwise, manual macro entry remains available.

Heroku Deployment, Added edge case test cases
