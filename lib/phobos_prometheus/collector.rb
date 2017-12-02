require 'prometheus/client'

module PhobosPrometheus
  # Collector class to track events from Phobos Instrumentation
  class Collector
    # Buckets in ms for histogram
    BUCKETS = [5, 10, 25, 50, 100, 250, 500, 750, 1500, 3000, 5000].freeze

    attr_reader :registry, :listener_events_total, :listener_events_duration

    def initialize(options = {})
      @registry = options[:registry] || Prometheus::Client.registry
      @metrics_prefix = options[:metrics_prefix] || 'phobos_client'

      init_consumer_metrics
      subscribe_consumer_metrics
    end

    protected

    EVENT_LABEL_BUILDER = proc do |event|
      {
        topic:    event.payload[:topic],
        group_id: event.payload[:group_id],
        handler:  event.payload[:handler]
      }
    end

    def init_consumer_metrics
      @listener_events_total = @registry.counter(
        :"#{@metrics_prefix}_listener_events_total",
        'The total number of events handled.'
      )
      @listener_events_duration = @registry.histogram(
        :"#{@metrics_prefix}_listener_events_duration",
        'The duration spent (in ms) consuming events.',
        {},
        BUCKETS
      )
    end

    def subscribe_consumer_metrics
      Phobos::Instrumentation.subscribe('listener.process_message') do |event|
        @listener_events_total.increment(EVENT_LABEL_BUILDER.call(event))
        @listener_events_duration.observe(EVENT_LABEL_BUILDER.call(event), event.duration)
      end
    rescue
      # TODO: log unexpected exception during request recording
      nil
    end
  end
end
