require 'prometheus/client'

module PhobosPrometheus
  class Collector
    attr_reader :registry, :event_total, :event_durations

    def initialize(options = {})
      @registry = options[:registry] || Prometheus::Client.registry
      @metrics_prefix = options[:metrics_prefix] || 'phobos_client'

      init_event_metrics
      subscribe_event_metrics
    end

    protected

    EVENT_LABEL_BUILDER = proc do |event|
      {
        topic:    event.payload.topic,
        group_id: event.payload.group_id,
        handler:  event.payload.handler
      }
    end

    def init_event_metrics
      @event_total = @registry.counter(
        :"#{@metrics_prefix}_total_events_handled",
        'The total number of kafka events handled by the Phobos application.',
      )
      @event_durations = @registry.histogram(
        :"#{@metrics_prefix}_events_handled_duration",
        'The event consume duration in ms of the Phobos application.',
      )
    end

    def subscribe_event_metrics
      Phobos::Instrumentation.subscribe('listener.process_message') do |event|
        @event_total.increment(EVENT_LABEL_BUILDER.call(event))
        @event_durations.observe(EVENT_LABEL_BUILDER.call(event), event.duration)
      end
    end
  end
end
