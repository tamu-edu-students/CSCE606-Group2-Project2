# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
Local test database with Docker
-------------------------------
If you don't have PostgreSQL locally, you can use the provided docker-compose file to run a PostgreSQL instance for tests.

Start a test Postgres container (in a separate terminal):

```bash
docker compose -f docker-compose.test.yml up -d
```

Then create and migrate the test database and run Cucumber:

```bash
export PGHOST=127.0.0.1
export PGPORT=55432
export PGUSER=postgres
export PGPASSWORD=postgres
RAILS_ENV=test bin/rails db:create db:migrate
bundle exec cucumber
```

Stop the container when done:

```bash
docker compose -f docker-compose.test.yml down
```

