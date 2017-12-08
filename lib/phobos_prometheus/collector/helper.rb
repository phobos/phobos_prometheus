# frozen_string_literal: true

module PhobosPrometheus
  module Collector
    # Shared code between collectors.
    # Using module to avoid introducing inheritance
    module Helper
      attr_reader :registry

      def self.included(base)
        base.extend ClassMethods
      end

      # ClassMethods will be extended upon inclusion
      module ClassMethods
        def handle?(type)
          type == self::TYPE
        end
      end

      def setup_collector_module(instrumentation_label:)
        @instrumentation_label = instrumentation_label
        @registry = Prometheus::Client.registry
        @metrics_prefix = PhobosPrometheus.config.metrics_prefix || 'phobos_client'

        init_metrics(instrumentation_label.sub('.', '_'))
        subscribe_metrics
      end

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
  end
end
