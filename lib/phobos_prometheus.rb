# frozen_string_literal: true

require 'ostruct'
require 'yaml'

require 'phobos'
require 'prometheus/client'
require 'prometheus/client/formats/text'
require 'sinatra/base'

require 'phobos_prometheus/version'
require 'phobos_prometheus/collector'
require 'phobos_prometheus/collector/histogram'
require 'phobos_prometheus/collector/counter'
require 'phobos_prometheus/exporter_helper'
require 'phobos_prometheus/exporter'

# Prometheus collector for Phobos
module PhobosPrometheus
  class << self
    attr_reader :config, :metrics

    def subscribe
      config.metrics.each do |metric|
        metric.types.each do |type|
          metrics << register(
            type: type, buckets: bucket_config(metric.bucket),
            instrumentation_label: metric.instrumentation_label
          )
        end
      end

      Phobos.logger.info { Hash(message: 'PhobosPrometheus subscribed', env: ENV['RACK_ENV']) }

      self
    end

    def configure(configuration)
      @metrics ||= []
      @config = Phobos::DeepStruct.new(fetch_settings(configuration))

      Phobos.logger.info { Hash(message: 'PhobosPrometheus configured', env: ENV['RACK_ENV']) }
    end

    private

    def fetch_settings(configuration)
      return configuration.to_h if configuration.respond_to?(:to_h)

      YAML.safe_load(ERB.new(File.read(File.expand_path(configuration))).result)
    end

    def register(type:, instrumentation_label:, buckets:)
      case type
      when 'counter'
        Collector::Counter.create(instrumentation_label: instrumentation_label)
      when 'histogram'
        Collector::Histogram.create(
          instrumentation_label: instrumentation_label,
          buckets: buckets
        )
      end
    end

    def bucket_config(name)
      config.buckets.find { |b| b.name == name }&.buckets
    end
  end
end
