require 'bundler/setup'
require 'phobos_prometheus'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each, :configured) { PhobosPrometheus.configure('spec/fixtures/phobos_prometheus.yml') }
  config.after(:each, :configured) { PhobosPrometheus.instance_variable_set(:@config, nil) }
end
