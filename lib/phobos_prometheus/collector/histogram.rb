# frozen_string_literal: true

module PhobosPrometheus
  # Collector class to track events from Phobos Instrumentation
  module Collector
    class Histogram
      include Helper
      attr_reader :registry, :histogram

      # Buckets in ms for histogram
      BUCKETS = [5, 10, 25, 50, 100, 250, 500, 750, 1500, 3000, 5000].freeze

      def self.create(instrumentation_label:, buckets: BUCKETS)
        new(instrumentation_label: instrumentation_label, buckets: buckets)
      end

      def initialize(instrumentation_label:, buckets:)
        @buckets = buckets
        super(instrumentation_label: instrumentation_label)
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