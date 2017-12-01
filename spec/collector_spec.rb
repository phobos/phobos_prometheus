RSpec.describe PhobosPrometheus::Collector do
  include Phobos::Instrumentation

  let(:registry) do
    Prometheus::Client::Registry.new
  end

  let(:process_message_metadata) do
    {
      listener_id: 'listener_id',
      key: 'key',
      partition: 'partition',
      offset: 'offset',
      retry_count: 0
    }
  end

  def emit_event(group_id:, topic:, handler:)
    instrument(
      'listener.process_message',
      process_message_metadata.merge(group_id: group_id, topic: topic, handler: handler)
    )
  end

  def emit_sample_events
    buckets = described_class::BUCKETS.map { |v| v / 1000.0 }[0..3]
    values = [0, 0, 0, 0].zip(buckets).flatten
    allow(Time).to receive(:now).and_return(*values)
    emit_event(group_id: 'group_1', topic: 'topic_1', handler: 'AppHandlerOne')
    emit_event(group_id: 'group_2', topic: 'topic_2', handler: 'AppHandlerOne')
    emit_event(group_id: 'group_2', topic: 'topic_2', handler: 'AppHandlerTwo')
    emit_event(group_id: 'group_2', topic: 'topic_2', handler: 'AppHandlerTwo')
  end

  describe 'consumer events' do
    let(:subject) { described_class.new }

    before :each do
      allow(Prometheus::Client).to receive(:registry).and_return(registry)
      subject

      emit_sample_events
    end

    it 'tracks total events' do
      expect(subject.listener_events_total.values)
        .to match({ topic: 'topic_1', group_id: 'group_1', handler: 'AppHandlerOne' } => 1.0,
                  { topic: 'topic_2', group_id: 'group_2', handler: 'AppHandlerOne' } => 1.0,
                  { topic: 'topic_2', group_id: 'group_2', handler: 'AppHandlerTwo' } => 2.0)
    end

    it 'track total duration' do
      expect(subject.listener_events_duration.values)
        .to match(
          { topic: 'topic_1', group_id: 'group_1', handler: 'AppHandlerOne' } =>
            { 5 => 0.0, 10 => 1.0, 25 => 1.0, 50 => 1.0, 100 => 1.0, 250 => 1.0, 500 => 1.0, 750 => 1.0, 1500 => 1.0, 3000 => 1.0, 5000 => 1.0 },
          { topic: 'topic_2', group_id: 'group_2', handler: 'AppHandlerOne' } =>
            { 5 => 0.0, 10 => 0.0, 25 => 0.0, 50 => 1.0, 100 => 1.0, 250 => 1.0, 500 => 1.0, 750 => 1.0, 1500 => 1.0, 3000 => 1.0, 5000 => 1.0 },
          { topic: 'topic_2', group_id: 'group_2', handler: 'AppHandlerTwo' } =>
            { 5 => 2.0, 10 => 2.0, 25 => 2.0, 50 => 2.0, 100 => 2.0, 250 => 2.0, 500 => 2.0, 750 => 2.0, 1500 => 2.0, 3000 => 2.0, 5000 => 2.0 }
        )
    end
  end
end
