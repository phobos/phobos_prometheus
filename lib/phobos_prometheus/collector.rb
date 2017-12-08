# frozen_string_literal: true

module PhobosPrometheus
  # Collector dispatches creation of the desired metric types
  module Collector
    METRIC_TYPES = [Counter, Histogram].freeze

    EVENT_LABEL_BUILDER = proc do |event|
      {
        topic:    event.payload[:topic],
        group_id: event.payload[:group_id],
        handler:  event.payload[:handler]
      }
    end

    def self.create(type:, instrumentation_label:, buckets:)
      METRIC_TYPES
        .find { |klass| klass.handle?(type) }
        .create(
          instrumentation_label: instrumentation_label,
          buckets: buckets
        )
    end
  end
end
