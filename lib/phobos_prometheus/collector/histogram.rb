# frozen_string_literal: true

module PhobosPrometheus
  module Collector
    # Collector class to track histogram events
    class Histogram
      include Helper
      attr_reader :histogram

      # Buckets in ms for histogram
      BUCKETS = [5, 10, 25, 50, 100, 250, 500, 750, 1500, 3000, 5000].freeze

      def self.create(config)
        new(
          instrumentation: config[:instrumentation],
          bucket_name: config[:bucket_name]
        )
      end

      def initialize(instrumentation:, bucket_name:)
        @metrics_prefix = @instrumentation = @registry = @histogram = nil
        @buckets = fetch_bucket_size(bucket_name) || BUCKETS
        setup_collector_module(instrumentation: instrumentation)
      end

      def fetch_bucket_size(bucket_name)
        PhobosPrometheus.config.buckets.find { |bucket| bucket.name = bucket_name }&.bins
      end

      def init_metrics(prometheus_label)
        @histogram = @registry.histogram(
          :"#{@metrics_prefix}_#{prometheus_label}_duration",
          "The duration spent (in ms) consuming #{@instrumentation} events.",
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
