# frozen_string_literal: true

RSpec.describe PhobosPrometheus::Collector::Counter, :configured do
  include Phobos::Instrumentation

  let(:instrumentation) { 'listener.process_message' }
  let(:subject) do
    described_class.create(
      instrumentation: instrumentation
    )
  end

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

  def emit_event(group_id:, topic:, handler:)
    instrument(
      instrumentation,
      process_message_metadata.merge(group_id: group_id, topic: topic, handler: handler)
    )
  end

  def buckets
    PhobosPrometheus::Collector::Histogram::BUCKETS.map { |value| value / 1000.0 }[0..3]
  end

  def emit_sample_events
    allow(Time).to receive(:now).and_return(*[0, 0, 0, 0].zip(buckets).flatten)
    emit_event(group_id: 'group_1', topic: 'topic_1', handler: 'AppHandlerOne')
    emit_event(group_id: 'group_2', topic: 'topic_2', handler: 'AppHandlerOne')
    2.times { emit_event(group_id: 'group_2', topic: 'topic_2', handler: 'AppHandlerTwo') }
  end

  describe 'consumer events' do
    before :each do
      allow(Prometheus::Client).to receive(:registry).and_return(registry)
      subject

      emit_sample_events
    end

    it 'tracks total events' do
      expect(subject.counter.values)
        .to match({ topic: 'topic_1', group_id: 'group_1', handler: 'AppHandlerOne' } => 1.0,
                  { topic: 'topic_2', group_id: 'group_2', handler: 'AppHandlerOne' } => 1.0,
                  { topic: 'topic_2', group_id: 'group_2', handler: 'AppHandlerTwo' } => 2.0)
    end
  end

  context 'when exception occurs' do
    before :each do
      Phobos.configure(Hash(logger: Hash(level: :error)))
      Phobos.silence_log = true
      Phobos.configure_logger
      allow(Prometheus::Client).to receive(:registry).and_return(registry)
      subject
      allow(subject.counter).to receive(:increment).and_raise(StandardError, 'Boo')
    end

    it 'it swallows the exception' do
      expect do
        emit_event(group_id: 'group_1', topic: 'topic_1', handler: 'AppHandlerOne')
      end.to_not raise_error
    end

    it 'logs to error log' do
      expect(Phobos.logger).to receive(:error).with(Hash)
      emit_event(group_id: 'group_1', topic: 'topic_1', handler: 'AppHandlerOne')
    end
  end
end
