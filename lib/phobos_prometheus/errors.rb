# frozen_string_literal: true

module PhobosPrometheus
  # Exporter is a Rack application that provides a Prometheus HTTP exposition
  # endpoint.
  class Error < StandardError; end
  class InvalidConfigurationError < Error; end
end
