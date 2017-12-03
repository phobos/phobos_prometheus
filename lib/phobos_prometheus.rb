require 'ostruct'
require 'yaml'

require 'phobos/deep_struct'
require 'phobos/instrumentation'

require 'phobos_prometheus/version'
require 'phobos_prometheus/collector'
require 'phobos_prometheus/exporter'

# Prometheus collector for Phobos
module PhobosPrometheus
  class << self
    attr_reader :message_collector, :config

    def subscribe
      @message_collector ||= Collector.create('listener.process_message')
      self
    end

    def configure(configuration)
      @config = Phobos::DeepStruct.new(fetch_settings(configuration))
    end

    private

    def fetch_settings(configuration)
      return configuration.to_h if configuration.respond_to?(:to_h)

      YAML.load(ERB.new(File.read(File.expand_path(configuration))).result)
    end
  end
end
