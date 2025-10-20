# Enable SQLite WAL journal mode to reduce locking in concurrent test runs
begin
  require 'active_record'
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
    ActiveRecord::Base.connection.execute('PRAGMA journal_mode = WAL;')
  end
rescue StandardError
  # ignore if not using sqlite or connection not ready
end
