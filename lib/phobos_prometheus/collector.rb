# frozen_string_literal: true

module PhobosPrometheus
  # MetricsSubscriber dispatches creation of the desired metric types
  module Collector
    METRIC_TYPES = [Counter, Histogram].freeze

    EVENT_LABEL_BUILDER = proc do |event|
      {
        topic:    event.payload[:topic],
        group_id: event.payload[:group_id],
        handler:  event.payload[:handler]
      }
    end

    class Builder
      def initialize(type, metric)
        @type = type
        @instrumentation_label = metric.instrumentation_label
        @bucket = PhobosPrometheus
                  .config
                  .buckets
                  .find { |bucket| bucket.name == metric.bucket_name }
      end

      def subscribe
        METRIC_TYPES
          .find { |klass| klass.handle?(@type) }
          .create(
            instrumentation_label: @instrumentation_label,
            buckets: @bucket&.buckets
          )
      end
    end
  end
end
