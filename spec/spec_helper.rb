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

  config.around(:each, :configured) do |example|
    Phobos.silence_log = true
    Phobos.configure(Hash(logger: { stdout_json: true }))
    PhobosPrometheus.configure('spec/fixtures/phobos_prometheus.yml')
    example.run
    PhobosPrometheus.instance_variable_set(:@config, nil)
  end
end
