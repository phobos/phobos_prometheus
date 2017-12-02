require 'phobos/instrumentation'

require 'phobos_prometheus/version'
require 'phobos_prometheus/collector'
require 'phobos_prometheus/exporter'

# Prometheus collector for Phobos
module PhobosPrometheus
  class << self
    def configure(options = {})
      @collector ||= Collector.new(options)
    end
  end
end
