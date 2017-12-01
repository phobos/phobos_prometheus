require 'phobos/instrumentation'

require 'phobos_prometheus/version'
require 'phobos_prometheus/collector'

# Prometheus collector for Phobos
module PhobosPrometheus
  class << self
    def configure(options = {})
      @collector ||= Collector.new
    end
  end
end
