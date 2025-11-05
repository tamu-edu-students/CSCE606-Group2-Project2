## Diet Tracker Platform

This Rails 8 application helps users track daily calories and macros. Authenticated users can upload food photos for GPT-powered nutrition analysis, confirm the suggested entry, and monitor remaining targets on a clean dashboard. For accessibility, every workflow also supports manual entry with JavaScript disabled.

### Highlights
- Google OAuth login via OmniAuth (with graceful fallback in test mode).
- Onboarding survey that stores height, weight, activity level, and goals, then calculates personalized daily targets.
- Food logging with optional image upload passed to the OpenAI Vision API.
- Dashboard summarizing macros remaining and listing today's meals.
- Active Storage for image uploads, PostgreSQL-ready schema (SQLite in dev/test).
- Comprehensive test suite (RSpec + Cucumber) with >90% merged coverage enforced in CI.

### Getting Started
1. **Prerequisites**
   - Ruby `3.4.5` (see `.ruby-version`).
   - Bundler `>= 2.6`.
   - SQLite3 for local development.

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Database setup**
   ```bash
   bin/rails db:prepare
   ```

4. **Run the app**
   ```bash
   bin/rails server
   ```
   Visit `http://localhost:3000` and sign in with Google.

### Environment Configuration
Create `.env` / configure your shell with the following variables:

| Variable | Required | Purpose |
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