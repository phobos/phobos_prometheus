RSpec.shared_context 'for counter and histogram', shared_context: :metadata do
  let(:registry) do
    Prometheus::Client::Registry.new
  end

  let(:process_message_metadata) do
    {
      id: 'id',
      key: 'key',
      partition: 'partition',
      offset: 'offset',
      retry_count: 0
    }
  end

  BUCKETS = PhobosPrometheus::Collector::Histogram::BUCKETS.map { |value| value / 1000.0 }[0..3]

  def emit_event(group_id:, topic:, handler:)
    instrument(
      instrumentation,
      process_message_metadata.merge(group_id: group_id, topic: topic, handler: handler)
    )
  end

  def emit_sample_events
    allow(Time).to receive(:now).and_return(*[0, 0, 0, 0].zip(BUCKETS).flatten)
    emit_event(group_id: 'group_1', topic: 'topic_1', handler: 'AppHandlerOne')
    emit_event(group_id: 'group_2', topic: 'topic_2', handler: 'AppHandlerOne')
    2.times { emit_event(group_id: 'group_2', topic: 'topic_2', handler: 'AppHandlerTwo') }
  end

  before(:each) do
    allow(Prometheus::Client).to receive(:registry).and_return(registry)
  end
end
