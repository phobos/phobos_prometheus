# frozen_string_literal: true

RSpec.describe PhobosPrometheus::Collector::Histogram, :configured do
  include_context 'for counter and histogram', include_shared: true

  let(:instrumentation) { 'listener.process_batch' }
  let!(:subject) do
    described_class.create(
      instrumentation: instrumentation,
      bucket_name: 'batch'
    )
  end

  describe 'consumer events' do
    before :each do
      emit_sample_events
    end

    it 'track total duration' do
      expect(subject.histogram.values)
        .to match(
          { topic: 'topic_1', group_id: 'group_1', handler: 'AppHandlerOne' } =>
            { 100 => 1.0, 250 => 1.0, 500 => 1.0, 750 => 1.0, 1000 => 1.0,
              2500 => 1.0, 5000 => 1.0, 10_000 => 1.0, 15_000 => 1.0 },
          { topic: 'topic_2', group_id: 'group_2', handler: 'AppHandlerOne' } =>
            { 100 => 1.0, 250 => 1.0, 500 => 1.0, 750 => 1.0, 1000 => 1.0,
              2500 => 1.0, 5000 => 1.0, 10_000 => 1.0, 15_000 => 1.0 },
          { topic: 'topic_2', group_id: 'group_2', handler: 'AppHandlerTwo' } =>
            { 100 => 2.0, 250 => 2.0, 500 => 2.0, 750 => 2.0, 1000 => 2.0,
              2500 => 2.0, 5000 => 2.0, 10_000 => 2.0, 15_000 => 2.0 }
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
