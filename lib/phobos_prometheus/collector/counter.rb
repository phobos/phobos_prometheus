# frozen_string_literal: true

module PhobosPrometheus
  module Collector
    # Collector class to track counter events
    class Counter
      include Helper
      attr_reader :counter

      def self.create(config)
        instrumentation = config[:instrumentation]
        raise(InvalidConfigurationError, 'Counter requires :instrumentation') \
          unless instrumentation

        new(instrumentation: instrumentation)
      end

      def initialize(instrumentation:)
        @metrics_prefix = @instrumentation = @registry = @counter = nil
        setup_collector_module(instrumentation: instrumentation)
      end

      def init_metrics(prometheus_label)
        @counter = @registry.counter(
          :"#{@metrics_prefix}_#{prometheus_label}_total",
          "The total number of #{@instrumentation} events handled."
        )
      end

      def update_metrics(event_label, _event)
        @counter.increment(event_label)
      end
    end
  end
end
