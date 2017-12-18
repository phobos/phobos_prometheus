# frozen_string_literal: true

RSpec.describe PhobosPrometheus do
  let(:config_path) { 'spec/fixtures/phobos_prometheus.yml' }

  it 'has a version number' do
    expect(PhobosPrometheus::VERSION).not_to be nil
  end

  describe '.subscribe', :configured do
    let(:registry) do
      Prometheus::Client::Registry.new
    end

    before :each do
      allow(Prometheus::Client).to receive(:registry).and_return(registry)
    end

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

    it 'configures buckets correctly' do
      PhobosPrometheus.subscribe

      histograms = PhobosPrometheus
                   .metrics
                   .grep(PhobosPrometheus::Collector::Histogram)
                   .map(&:histogram)

      message_histogram = histograms.find do |histogram|
        histogram.name == :phobos_app_listener_process_message_duration
      end

      batch_histogram = histograms.find do |histogram|
        histogram.name == :phobos_app_listener_process_batch_duration
      end

      expect(message_histogram.instance_variable_get(:@buckets))
        .to eq(PhobosPrometheus.config.buckets[0].bins)
      expect(batch_histogram.instance_variable_get(:@buckets))
        .to eq(PhobosPrometheus.config.buckets[1].bins)
    end
  end

  describe '.configure', :with_logger do
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
