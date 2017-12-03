RSpec.describe PhobosPrometheus do
  let(:config_path) { 'spec/fixtures/phobos_prometheus.yml' }

  it 'has a version number' do
    expect(PhobosPrometheus::VERSION).not_to be nil
  end

  describe '.subscribe', :configured do
    it 'creates a collector object' do
      expect(PhobosPrometheus::Collector).to receive(:create)
      PhobosPrometheus.subscribe
    end

    it 'memorizes the collector object' do
      collector = PhobosPrometheus.subscribe.message_collector
      collector2 = PhobosPrometheus.subscribe.message_collector
      expect(collector).to eql(collector2)
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
