# frozen_string_literal: true

module PhobosPrometheus
  module Collector
    EVENT_LABEL_BUILDER = proc do |event|
      {
        topic:    event.payload[:topic],
        group_id: event.payload[:group_id],
        handler:  event.payload[:handler]
      }
    end

    module Helper
      def subscribe_metrics
        Phobos::Instrumentation.subscribe(@instrumentation_label) do |event|
          safely_update_metrics(event)
        end
      end

      # rubocop:disable Lint/RescueWithoutErrorClass
      def safely_update_metrics(event)
        event_label = EVENT_LABEL_BUILDER.call(event)
        update_metrics(event_label, event)
      rescue => error
        ErrorLogger.new(error, event, @instrumentation_label).log
      end
      # rubocop:enable Lint/RescueWithoutErrorClass
    end

    # ErrorLogger logs errors to stdout
    class ErrorLogger
      def initialize(error, event, instrumentation_label)
        @error = error
        @event = event
        @instrumentation_label = instrumentation_label
      end

      def log
        Phobos.logger.error(
          Hash(
            message: 'PhobosPrometheus: Error occured in metrics handler for subscribed event',
            instrumentation_label: @instrumentation_label,
            event: @event,
            exception_class: @error.class.to_s,
            exception_message: @error.message,
            backtrace: @error.backtrace
          )
        )
      end
    end
  end
end
