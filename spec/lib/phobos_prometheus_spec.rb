RSpec.describe PhobosPrometheus do
  it 'has a version number' do
    expect(PhobosPrometheus::VERSION).not_to be nil
  end

  describe '.register_subscriber' do
    let(:options) { Hash(foo: :bar) }

    it 'creates a collector object with passed options' do
      expect(PhobosPrometheus::Collector).to receive(:new).with(options)
      PhobosPrometheus.register_subscriber(options)
    end

    it 'memorizes the collector object' do
      collector = PhobosPrometheus.register_subscriber(options).collector
      collector2 = PhobosPrometheus.register_subscriber(options).collector
      expect(collector).to eql(collector2)
    end
  end
end
