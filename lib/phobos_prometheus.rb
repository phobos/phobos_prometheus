require 'phobos/instrumentation'

require 'phobos_prometheus/version'
require 'phobos_prometheus/collector'
require 'phobos_prometheus/exporter'

# Prometheus collector for Phobos
module PhobosPrometheus
  class << self
    attr_reader :collector

    # rubocop:disable Style/ClassVars
    def configure(options = {})
      @@collector ||= Collector.new(options)
      self
    end
    # rubocop:enable Style/ClassVars
  end
end
