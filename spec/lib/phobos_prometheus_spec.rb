# frozen_string_literal: true

RSpec.describe PhobosPrometheus do
  let(:config_path) { 'spec/fixtures/phobos_prometheus.yml' }

  it 'has a version number' do
    expect(PhobosPrometheus::VERSION).not_to be nil
  end

  describe '.subscribe', :configured do
    it 'creates a collector object as per configuration' do
      expect(PhobosPrometheus::Collector::Counter)
        .to receive(:create)
        .with(PhobosPrometheus.config.counters[0])
        .ordered
        .and_call_original

      expect(PhobosPrometheus::Collector::Counter)
        .to receive(:create)
        .with(PhobosPrometheus.config.counters[1])
        .ordered
        .and_call_original

      expect(PhobosPrometheus::Collector::Counter)
        .to receive(:create)
        .with(PhobosPrometheus.config.counters[2])
        .ordered
        .and_call_original

      expect(PhobosPrometheus::Collector::Histogram)
        .to receive(:create)
        .with(PhobosPrometheus.config.histograms[0])
        .ordered
        .and_call_original

      expect(PhobosPrometheus::Collector::Histogram)
        .to receive(:create)
        .with(PhobosPrometheus.config.histograms[1])
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
      it 'does not parse it correctly' do
        expect do
          PhobosPrometheus.configure(metrics_prefix: 'foo')
        end.to raise_error TypeError
      end
    end
  end
end
