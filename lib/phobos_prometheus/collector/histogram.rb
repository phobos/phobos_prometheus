# frozen_string_literal: true

module PhobosPrometheus
  # Collector class to track events from Phobos Instrumentation
  module Collector
    class Histogram
      attr_reader :registry, :histogram

      # Buckets in ms for histogram
      BUCKETS = [5, 10, 25, 50, 100, 250, 500, 750, 1500, 3000, 5000].freeze

      def self.create(instrumentation_label:, buckets: BUCKETS)
        new(instrumentation_label: instrumentation_label, buckets: buckets)
      end

      def initialize(instrumentation_label:, buckets:)
        @instrumentation_label = instrumentation_label
        @buckets = buckets
        @registry = Prometheus::Client.registry
        @metrics_prefix = PhobosPrometheus.config.metrics_prefix || 'phobos_client'

        init_metrics(instrumentation_label.sub('.', '_'))
        subscribe_metrics
      end

      protected

      def init_metrics(prometheus_label)
        @histogram = @registry.histogram(
          :"#{@metrics_prefix}_#{prometheus_label}_duration",
          "The duration spent (in ms) consuming #{@instrumentation_label} events.",
          {},
          @buckets
        )
      end

      def subscribe_metrics
        Phobos::Instrumentation.subscribe(@instrumentation_label) do |event|
          update_metrics(event)
        end
      end

      # rubocop:disable Lint/RescueWithoutErrorClass
      def update_metrics(event)
        event_label = EVENT_LABEL_BUILDER.call(event)
        @histogram.observe(event_label, event.duration)
      rescue => error
        ErrorLogger.new(error, event, @instrumentation_label).log
      end
      # rubocop:enable Lint/RescueWithoutErrorClass
    end
  end
end
