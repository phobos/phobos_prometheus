# frozen_string_literal: true

module PhobosPrometheus
  module Collector
    # Shared code between collectors.
    # Using module to avoid introducing inheritance
    module Helper
      attr_reader :registry

      def setup_collector_module(instrumentation:)
        @instrumentation = instrumentation
        @registry = Prometheus::Client.registry
        @metrics_prefix = PhobosPrometheus.config.metrics_prefix || 'phobos_client'

        init_metrics(instrumentation.sub('.', '_'))
        subscribe_metrics
      end

      def subscribe_metrics
        Phobos::Instrumentation.subscribe(@instrumentation) do |event|
          safely_update_metrics(event)
        end
      end

      def safely_update_metrics(event)
        event_label = EVENT_LABEL_BUILDER.call(event)
        update_metrics(event_label, event)
      rescue StandardError => error
        ErrorLogger.new(error, event, @instrumentation).log
      end
    end
  end
end
