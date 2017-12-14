# frozen_string_literal: true

require 'ostruct'
require 'yaml'

require 'phobos'
require 'prometheus/client'
require 'prometheus/client/formats/text'
require 'sinatra/base'

require 'phobos_prometheus/version'
require 'phobos_prometheus/errors'
require 'phobos_prometheus/logger'
require 'phobos_prometheus/config_parser'
require 'phobos_prometheus/collector/helper'
require 'phobos_prometheus/collector/error_logger'
require 'phobos_prometheus/collector/histogram'
require 'phobos_prometheus/collector/counter'
require 'phobos_prometheus/collector/gauge'
require 'phobos_prometheus/collector'
require 'phobos_prometheus/exporter_helper'
require 'phobos_prometheus/exporter'

# Prometheus collector for Phobos
module PhobosPrometheus
  class << self
    include Logger
    attr_reader :config, :metrics

    # Public - configure and validate configuration
    def configure(path)
      @metrics ||= []
      @config = ConfigParser.new(path).config

      log_info('PhobosPrometheus configured')
    end

    # Public - after configured create the prometheus metrics
    def subscribe
      subscribe_counters
      subscribe_histograms
      subscribe_gauges

      log_info('PhobosPrometheus subscribed') unless @metrics.empty?

      self
    end

    private

    def subscribe_counters
      @config.counters.each do |counter|
        @metrics << PhobosPrometheus::Collector::Counter.create(counter)
      end
    end

    def subscribe_histograms
      @config.histograms.each do |histogram|
        @metrics << PhobosPrometheus::Collector::Histogram.create(histogram)
      end
    end

    def subscribe_gauges
      @config.gauges.each do |gauge|
        @metrics << PhobosPrometheus::Collector::Gauge.create(gauge)
      end
    end
  end
end
