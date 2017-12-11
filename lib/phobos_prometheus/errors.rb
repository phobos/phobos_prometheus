# frozen_string_literal: true

module PhobosPrometheus
  # Base error class
  class Error < StandardError; end
  # Error class for invalid configuration
  class InvalidConfigurationError < Error; end
end
