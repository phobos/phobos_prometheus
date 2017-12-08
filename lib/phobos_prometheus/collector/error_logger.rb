# frozen_string_literal: true

module PhobosPrometheus
  module Collector
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
