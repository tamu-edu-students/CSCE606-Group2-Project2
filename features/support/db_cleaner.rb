# Ensure a clean test DB for each scenario by truncating application tables.
require 'active_record'

Before do
  conn = ActiveRecord::Base.connection
  tables = conn.tables - ['schema_migrations', 'ar_internal_metadata']
  tables.each do |table|
    conn.execute("DELETE FROM \"#{table}\"")
  end
end