# frozen_string_literal: true

module PhobosPrometheus
  # Collector class to track events from Phobos Instrumentation
  module Collector
    class Counter
      include Helper
      attr_reader :registry, :counter

      def self.create(instrumentation_label:)
        new(instrumentation_label: instrumentation_label)
      end

      def initialize(args)
        super(args)
      end

      def init_metrics(prometheus_label)
        @counter = @registry.counter(
          :"#{@metrics_prefix}_#{prometheus_label}_total",
          "The total number of #{@instrumentation_label} events handled."
        )
      end

      def update_metrics(event_label, _event)
        @counter.increment(event_label)
      end
    end
  end
end
