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
      @listener_events_total = @listener_events_duration = nil
      @instrumentation_label = instrumentation_label
      @registry = Prometheus::Client.registry
      @metrics_prefix = PhobosPrometheus.config.metrics_prefix || 'phobos_client'

      init_metrics(instrumentation_label.sub('.', '_'))
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

    def init_metrics(prometheus_label)
      @listener_events_total = @registry.counter(
        :"#{@metrics_prefix}_#{prometheus_label}_total",
        "The total number of #{@instrumentation_label} events handled."
      )
      @listener_events_duration = @registry.histogram(
        :"#{@metrics_prefix}_#{prometheus_label}_duration",
        "The duration spent (in ms) consuming #{@instrumentation_label} events.",
        {},
        BUCKETS
      )
    end

    def subscribe_metrics
      Phobos::Instrumentation.subscribe(@instrumentation_label) do |event|
        update_metrics(event)
      end
    end

    # rubocop:disable Lint/RescueWithoutErrorClass
    def update_metrics(event)
      event_label = Collector::EVENT_LABEL_BUILDER.call(event)
      @listener_events_total.increment(event_label)
      @listener_events_duration.observe(event_label, event.duration)
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
