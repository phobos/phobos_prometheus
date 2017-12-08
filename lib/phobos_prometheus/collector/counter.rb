# frozen_string_literal: true

module PhobosPrometheus
  # Collector class to track events from Phobos Instrumentation
  module Collector
    class Counter
      include Helper
      attr_reader :registry, :counter

      def self.create(instrumentation_label:)
        new(instrumentation_label: instrumentation_label)
      end

      def initialize(instrumentation_label:)
        @instrumentation_label = instrumentation_label
        @registry = Prometheus::Client.registry
        @metrics_prefix = PhobosPrometheus.config.metrics_prefix || 'phobos_client'

        init_metrics(instrumentation_label.sub('.', '_'))
        subscribe_metrics
      end

      def init_metrics(prometheus_label)
        @counter = @registry.counter(
          :"#{@metrics_prefix}_#{prometheus_label}_total",
          "The total number of #{@instrumentation_label} events handled."
        )
      end

      def update_metrics(event_label, _event)
        @counter.increment(event_label)
      end
    end
  end
end
