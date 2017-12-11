# frozen_string_literal: true

RSpec.describe PhobosPrometheus::Collector::Histogram, :configured do
  include Phobos::Instrumentation

  let(:instrumentation) { 'listener.process_batch' }
  let(:subject) do
    described_class.create(
      instrumentation: instrumentation,
      bucket_name: 'batch'
    )
  end

  let(:registry) do
    Prometheus::Client::Registry.new
  end

  let(:process_batch_metadata) do
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
      process_batch_metadata.merge(group_id: group_id, topic: topic, handler: handler)
    )
  end

  BUCKETS = PhobosPrometheus::Collector::Histogram::BUCKETS.map { |value| value / 1000.0 }[0..3]

  def emit_sample_events
    allow(Time).to receive(:now).and_return(*[0, 0, 0, 0].zip(BUCKETS).flatten)
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

    it 'track total duration' do
      expect(subject.histogram.values)
        .to match(
          { topic: 'topic_1', group_id: 'group_1', handler: 'AppHandlerOne' } =>
            { 5 => 1.0, 10 => 1.0, 25 => 1.0, 50 => 1.0, 100 => 1.0, 250 => 1.0, 500 => 1.0,
              750 => 1.0, 1000 => 1.0, 2500 => 1.0, 5000 => 1.0 },
          { topic: 'topic_2', group_id: 'group_2', handler: 'AppHandlerOne' } =>
            { 5 => 0.0, 10 => 1.0, 25 => 1.0, 50 => 1.0, 100 => 1.0, 250 => 1.0, 500 => 1.0,
              750 => 1.0, 1000 => 1.0, 2500 => 1.0, 5000 => 1.0 },
          { topic: 'topic_2', group_id: 'group_2', handler: 'AppHandlerTwo' } =>
            { 5 => 0.0, 10 => 0.0, 25 => 1.0, 50 => 2.0, 100 => 2.0, 250 => 2.0, 500 => 2.0,
              750 => 2.0, 1000 => 2.0, 2500 => 2.0, 5000 => 2.0 }
        )
    end
  end

  context 'when exception occurs' do
    before :each do
      Phobos.configure(Hash(logger: Hash(level: :error)))
      Phobos.silence_log = true
      Phobos.configure_logger
      allow(Prometheus::Client).to receive(:registry).and_return(registry)
      subject
      allow(subject.histogram).to receive(:observe).and_raise(StandardError, 'Boo')
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
