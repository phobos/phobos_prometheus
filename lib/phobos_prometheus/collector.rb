require 'phobos'
require 'prometheus/client'

module PhobosPrometheus
  # Collector class to track events from Phobos Instrumentation
  class Collector
    attr_reader :registry, :listener_events_total, :listener_events_duration

    # Buckets in ms for histogram
    BUCKETS = [5, 10, 25, 50, 100, 250, 500, 750, 1500, 3000, 5000].freeze

    def self.create(instrumentation_label)
      new(instrumentation_label)
    end

    def initialize(instrumentation_label)
      @instrumentation_label = instrumentation_label
      @prometheus_label = instrumentation_label.sub('.', '_')

      @registry = Prometheus::Client.registry
      @metrics_prefix = PhobosPrometheus.config.metrics_prefix || 'phobos_client'

      init_metrics
      subscribe_metrics
    end

    protected

    EVENT_LABEL_BUILDER = proc do |event|
      {
        topic:    event.payload[:topic],
        group_id: event.payload[:group_id],
        handler:  event.payload[:handler]
      }
    end

    def init_metrics
      @listener_events_total = @registry.counter(
        :"#{@metrics_prefix}_#{@prometheus_label}_total",
        "The total number of #{@instrumentation_label} events handled."
      )
      @listener_events_duration = @registry.histogram(
        :"#{@metrics_prefix}_#{@prometheus_label}_duration",
        "The duration spent (in ms) consuming #{@instrumentation_label} events.",
        {},
        BUCKETS
      )
    end

    # rubocop:disable Lint/RescueWithoutErrorClass
    def subscribe_metrics
      Phobos::Instrumentation.subscribe(@instrumentation_label) do |event|
        begin
          @listener_events_total
            .increment(Collector::EVENT_LABEL_BUILDER.call(event))
          @listener_events_duration
            .observe(Collector::EVENT_LABEL_BUILDER.call(event), event.duration)
        rescue => error
          log_error(error, event)
        end
      end
    end
    # rubocop:enable Lint/RescueWithoutErrorClass

    def log_error(error, event)
      Phobos.logger.error(Hash(
                            message: 'PhobosPrometheus: Error occured in metrics handler ' \
                                     'for subscribed event',
                            instrumentation_label: @instrumentation_label,
                            event: event,
                            exception_class: error.class.to_s,
                            exception_message: error.message,
                            backtrace: error.backtrace
      ))
    end
  end
end
