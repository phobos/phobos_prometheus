# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'bundler/setup'
require 'phobos_prometheus'
require './spec/support/collector_context.rb'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # This config option will be enabled by default on RSpec 4,
  # but for reasons of backwards compatibility, you have to
  # set it on RSpec 3.
  #
  # It causes the host group and examples to inherit metadata
  # from the shared context.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around(:each, :with_logger) do |example|
    Phobos.silence_log = true
    Phobos.configure(Hash(logger: { stdout_json: true }))
    example.run
  end

  config.after(:each, :clear_config) do
    PhobosPrometheus.instance_variable_set(:@config, nil)
    PhobosPrometheus.instance_variable_set(:@metrics, [])
  end

  config.around(:each, :configured) do |example|
    Phobos.silence_log = true
    Phobos.configure(Hash(logger: { stdout_json: true }))
    PhobosPrometheus.configure('spec/fixtures/phobos_prometheus.yml')
    example.run
    PhobosPrometheus.instance_variable_set(:@config, nil)
    PhobosPrometheus.instance_variable_set(:@metrics, [])
  end
end
