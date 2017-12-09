# frozen_string_literal: true

require 'ostruct'
require 'yaml'

require 'phobos'
require 'prometheus/client'
require 'prometheus/client/formats/text'
require 'sinatra/base'

require 'phobos_prometheus/version'
require 'phobos_prometheus/config'
require 'phobos_prometheus/collector/helper'
require 'phobos_prometheus/collector/error_logger'
require 'phobos_prometheus/collector/histogram'
require 'phobos_prometheus/collector/counter'
require 'phobos_prometheus/collector'
require 'phobos_prometheus/exporter_helper'
require 'phobos_prometheus/exporter'

# Prometheus collector for Phobos
module PhobosPrometheus
  class << self
    attr_reader :config, :metrics

    def subscribe
      config.counters.each do |counter|
        @metrics << PhobosPrometheus::Collector::Counter.create(counter)
      end

      config.histograms.each do |histogram|
        @metrics << PhobosPrometheus::Collector::Histogram.create(histogram)
      end

      Phobos.logger.info { Hash(message: 'PhobosPrometheus subscribed', env: ENV['RACK_ENV']) }

      self
    end

    def configure(path)
      @metrics ||= []
      @config = Config.fetch(path)

      Phobos.logger.info { Hash(message: 'PhobosPrometheus configured', env: ENV['RACK_ENV']) }
    end
  end
end
