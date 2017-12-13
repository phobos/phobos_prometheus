# frozen_string_literal: true

RSpec.describe PhobosPrometheus::Collector::Gauge, :configured do
  include Phobos::Instrumentation

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

  let(:label) { 'active_listeners' }
  let(:stop) { 'listener.stop_handler' }
  let(:start) { 'listener.start_handler' }
  let(:subject) do
    described_class.create(
      label: label,
      increment: start,
      decrement: stop
    )
  end

  def emit(instrumentation:, group_id:, topic:, handler:)
    instrument(
      instrumentation,
      process_message_metadata.merge(group_id: group_id, topic: topic, handler: handler)
    )
  end

  def emit_sample_events
    allow(Time).to receive(:now).and_return(*[0, 0, 0, 0].zip(BUCKETS).flatten)
    4.times do
      emit(instrumentation: start, group_id: 'group_1', topic: 'topic_1', handler: 'AppHandlerOne')
    end
    4.times do
      emit(instrumentation: start, group_id: 'group_2', topic: 'topic_2', handler: 'AppHandlerOne')
    end
    2.times do
      emit(instrumentation: stop, group_id: 'group_2', topic: 'topic_2', handler: 'AppHandlerOne')
    end
  end

  describe 'consumer events' do
    before :each do
      allow(Prometheus::Client).to receive(:registry).and_return(registry)
      subject

      emit_sample_events
    end

    it 'tracks number of incremented - number of decremented' do
      expect(
        subject.gauge.get(topic: 'topic_1', group_id: 'group_1', handler: 'AppHandlerOne')
      ).to eq 4.0
      expect(
        subject.gauge.get(topic: 'topic_2', group_id: 'group_2', handler: 'AppHandlerOne')
      ).to eq 2.0
    end
  end

  context 'when exception occurs' do
    before :each do
      Phobos.configure(Hash(logger: Hash(level: :error)))
      Phobos.silence_log = true
      Phobos.configure_logger
      allow(Prometheus::Client).to receive(:registry).and_return(registry)
      subject
      allow(subject.gauge).to receive(:set).and_raise(StandardError, 'Boo')
    end

    it 'it swallows the exception' do
      expect do
        emit(
          instrumentation: start, group_id: 'group_1', topic: 'topic_1', handler: 'AppHandlerOne'
        )
      end.to_not raise_error
    end

    it 'logs to error log' do
      expect(Phobos.logger).to receive(:error).with(Hash)
      emit(instrumentation: start, group_id: 'group_1', topic: 'topic_1', handler: 'AppHandlerOne')
    end
  end
end
