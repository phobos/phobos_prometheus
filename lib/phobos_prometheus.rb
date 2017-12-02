require 'phobos/instrumentation'

require 'phobos_prometheus/version'
require 'phobos_prometheus/collector'
require 'phobos_prometheus/exporter'

# Prometheus collector for Phobos
module PhobosPrometheus
  class << self
    attr_reader :collector

    def register_subscriber(options = {})
      @collector ||= Collector.new(options)
      self
    end
  end
end
