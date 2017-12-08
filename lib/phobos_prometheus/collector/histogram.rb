# frozen_string_literal: true

module PhobosPrometheus
  module Collector
    # Collector class to track histogram events
    class Histogram
      include Helper
      attr_reader :histogram

      def self.handle?(type)
        type == 'histogram'
      end

      # Buckets in ms for histogram
      BUCKETS = [5, 10, 25, 50, 100, 250, 500, 750, 1500, 3000, 5000].freeze

      def self.create(args)
        new(
          instrumentation_label: args[:instrumentation_label],
          buckets: args[:buckets] || BUCKETS
        )
      end

      def initialize(instrumentation_label:, buckets:)
        @metrics_prefix = @instrumentation_label = @registry = @histogram = nil
        @buckets = buckets
        setup_collector_module(instrumentation_label: instrumentation_label)
      end

      def init_metrics(prometheus_label)
        @histogram = @registry.histogram(
          :"#{@metrics_prefix}_#{prometheus_label}_duration",
          "The duration spent (in ms) consuming #{@instrumentation_label} events.",
          {},
          @buckets
        )
      end

      def update_metrics(event_label, event)
        @histogram.observe(event_label, event.duration)
      end
    end
  end
end
