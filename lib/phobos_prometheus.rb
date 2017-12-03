require 'ostruct'
require 'yaml'

require 'phobos'
require 'prometheus/client'
require 'prometheus/client/formats/text'
require 'sinatra/base'

require 'phobos_prometheus/version'
require 'phobos_prometheus/collector'
require 'phobos_prometheus/exporter'

# Prometheus collector for Phobos
module PhobosPrometheus
  class << self
    attr_reader :message_collector, :batch_collector, :config

    def subscribe
      @message_collector ||= Collector.create('listener.process_message')
      @batch_collector ||= Collector.create('listener.process_batch')

      Phobos.logger.info { Hash(message: 'PhobosPrometheus subscribed', env: ENV['RACK_ENV']) }

      self
    end

    def configure(configuration)
      @config = Phobos::DeepStruct.new(fetch_settings(configuration))

      Phobos.logger.info { Hash(message: 'PhobosPrometheus configured', env: ENV['RACK_ENV']) }
    end

    private

    def fetch_settings(configuration)
      return configuration.to_h if configuration.respond_to?(:to_h)

      YAML.safe_load(ERB.new(File.read(File.expand_path(configuration))).result)
    end
  end
end
