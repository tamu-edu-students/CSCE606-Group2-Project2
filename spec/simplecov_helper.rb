# spec/simplecov_helper.rb
require 'simplecov'
require 'json'

# Allow an explicit command name to be provided by the environment (useful when
# $PROGRAM_NAME is 'bundle' and doesn't include the runner name).
if ENV['SIMPLECOV_COMMAND_NAME'] && !ENV['SIMPLECOV_COMMAND_NAME'].empty?
  SimpleCov.command_name ENV['SIMPLECOV_COMMAND_NAME']
else
  # Determine the test runner so we can set a sensible command name for merging
  runner = if (File.basename($PROGRAM_NAME) || '').downcase.include?('cucumber') || ENV['CUCUMBER']
             'Cucumber'
  else
             'RSpec'
  end

  SimpleCov.command_name "Tests:#{runner}"
end

SimpleCov.start 'rails' do
  # Filter out files that we don't need to test
  add_filter 'app/channels'
  add_filter 'app/jobs'
  add_filter 'app/mailers'
end

# At exit, format the results and print a concise coverage percentage.
# If you want to enforce a minimum coverage, set SIMPLECOV_MINIMUM (e.g. 90)
at_exit do
  # Write HTML report and merged results
  SimpleCov.result.format!

  result = SimpleCov.result
  coverage = result.covered_percent.round(2)

  puts "\nSimpleCov: #{coverage}% covered (#{SimpleCov.command_name})"

  if ENV['SIMPLECOV_MINIMUM']
    min = ENV['SIMPLECOV_MINIMUM'].to_f
    if coverage < min
      warn "SimpleCov: coverage (#{coverage}%) is below minimum (#{min}%), failing build."
      # Exit non-zero to fail CI when enforcing minimum coverage
      exit 1
    end
  end
end
