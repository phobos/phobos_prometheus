# frozen_string_literal: true

module PhobosPrometheus
  module Collector
    # Collector class to track gauge events
    class Gauge
      attr_reader :gauge, :registry

      def self.create(config)
        label = config[:label]
        increment = config[:increment]
        decrement = config[:decrement]

        raise(InvalidConfigurationError, 'Gauge requires :label, :increment and :decrement') \
          unless label && increment && decrement
        new(label: label, increment: increment, decrement: decrement)
      end

      def initialize(label:, increment:, decrement:)
        @registry = Prometheus::Client.registry
        @metrics_prefix = PhobosPrometheus.config.metrics_prefix || 'phobos_client'
        @increment = increment
        @decrement = decrement
        @label = label
        @gauge = @registry.gauge(
          :"#{@metrics_prefix}_#{label}", "The current count of #{@label}"
        )

        subscribe_metrics
      end

      def subscribe_metrics
        Phobos::Instrumentation.subscribe(@increment) do |event|
          safely_update_metrics(event, :increment)
        end

        Phobos::Instrumentation.subscribe(@decrement) do |event|
          safely_update_metrics(event, :decrement)
        end
      end

      # rubocop:disable Lint/RescueWithoutErrorClass
      def safely_update_metrics(event, operation)
        event_label = EVENT_LABEL_BUILDER.call(event)
        # .increment and .decrement is not released yet
        # @gauge.public_send(operation, event_label)
        current = @gauge.get(event_label) || 0
        if operation == :increment
          @gauge.set(event_label, current + 1)
        else
          @gauge.set(event_label, current - 1)
        end
      rescue => error
        ErrorLogger.new(error, event, @label).log
      end
      # rubocop:enable Lint/RescueWithoutErrorClass
    end
  end
end
