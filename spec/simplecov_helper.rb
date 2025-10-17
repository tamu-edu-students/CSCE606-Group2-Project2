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

  # Additionally compute and print the merged coverage across all saved results
  begin
    resultset_path = File.join(SimpleCov.root, 'coverage', '.resultset.json')
    if File.exist?(resultset_path)
      raw = JSON.parse(File.read(resultset_path))
      # Build a merged map: file_path -> array of booleans (covered or not)
      merged = {}
      raw.each_value do |entry|
        next unless entry && entry['coverage']
        entry['coverage'].each do |file, data|
          lines = data['lines'] || []
          merged[file] ||= Array.new(lines.length)
          lines.each_with_index do |val, idx|
            # consider covered if val is a positive number (or truthy non-zero)
            merged[file][idx] = true if val && val != 0
            # initialize false if nil and not yet set
            merged[file][idx] = false if merged[file][idx].nil?
          end
        end
      end

      total = 0
      covered = 0
      merged.each do |_file, arr|
        arr.each do |v|
          # skip nil entries (not relevant)
          next if v.nil?
          total += 1
          covered += 1 if v
        end
      end

      if total > 0
        merged_pct = ((covered.to_f / total) * 100).round(2)
        puts "Merged coverage: #{merged_pct}% (#{covered} / #{total} lines)"
        # Optionally enforce a minimum on merged coverage
        if ENV['SIMPLECOV_MINIMUM']
          min = ENV['SIMPLECOV_MINIMUM'].to_f
          if merged_pct < min
            warn "SimpleCov (merged): coverage (#{merged_pct}%) is below minimum (#{min}%), failing build."
            exit 1
          end
        end
      else
        puts "Merged coverage: no lines recorded"
      end
    end
  rescue => e
    warn "Failed to compute merged coverage: #{e.class}: #{e.message}"
  end

  if ENV['SIMPLECOV_MINIMUM']
    min = ENV['SIMPLECOV_MINIMUM'].to_f
    if coverage < min
      warn "SimpleCov: coverage (#{coverage}%) is below minimum (#{min}%), failing build."
      # Exit non-zero to fail CI when enforcing minimum coverage
      exit 1
    end
  end
end
