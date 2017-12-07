# frozen_string_literal: true

RSpec.describe PhobosPrometheus do
  let(:config_path) { 'spec/fixtures/phobos_prometheus.yml' }

  it 'has a version number' do
    expect(PhobosPrometheus::VERSION).not_to be nil
  end

  describe '.subscribe', :configured do
    it 'creates a collector object as per configuration' do
      expect(PhobosPrometheus::CounterCollector)
        .to receive(:create)
        .with(instrumentation_label: 'listener.process_message')
        .ordered
        .and_call_original

      expect(PhobosPrometheus::HistogramCollector)
        .to receive(:create)
        .with(
          instrumentation_label: 'listener.process_message',
          buckets: [5, 10, 25, 50, 100, 250, 500, 750, 1000, 2500, 5000]
        )
        .ordered
        .and_call_original

      expect(PhobosPrometheus::CounterCollector)
        .to receive(:create)
        .with(instrumentation_label: 'listener.process_batch')
        .ordered
        .and_call_original

      expect(PhobosPrometheus::HistogramCollector)
        .to receive(:create)
        .with(
          instrumentation_label: 'listener.process_batch',
          buckets: [100, 250, 500, 750, 1000, 2500, 5000, 10_000, 15_000]
        )
        .ordered
        .and_call_original

      expect(PhobosPrometheus::CounterCollector)
        .to receive(:create)
        .with(instrumentation_label: 'foo.counter_only')
        .ordered
        .and_call_original

      PhobosPrometheus.subscribe
    end
  end

  describe '.configure' do
    it 'creates the configuration obj' do
      PhobosPrometheus.configure(config_path)
      expect(PhobosPrometheus.config).to_not be_nil
      expect(PhobosPrometheus.config.metrics_prefix).to eq 'phobos_app'
    end

    context 'when using erb syntax in configuration file' do
      it 'parses it correctly' do
        PhobosPrometheus.configure('spec/fixtures/phobos_prometheus.yml.erb')

        expect(PhobosPrometheus.config).to_not be_nil
        expect(PhobosPrometheus.config.metrics_prefix).to eq('InjectedThroughERB')
      end
    end

    context 'when providing hash with configuration settings' do
      it 'parses it correctly' do
        PhobosPrometheus.configure(metrics_prefix: 'foo')

        expect(PhobosPrometheus.config).to_not be_nil
        expect(PhobosPrometheus.config.metrics_prefix).to eq('foo')
      end
    end
  end
end
