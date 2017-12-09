# frozen_string_literal: true

RSpec.describe PhobosPrometheus::Config do
  subject { described_class }

  describe '.fetch' do
    context 'with valid config' do
      let(:path) { './spec/fixtures/phobos_prometheus.yml' }

      it 'parses metrics_prefix' do
        config = subject.fetch(path)
        expect(config.metrics_prefix).to eq('phobos_app')
      end

      it 'parses counters' do
        config = subject.fetch(path)
        expect(config.counters)
          .to match([Phobos::DeepStruct.new(instrumentation: 'listener.process_message'),
                     Phobos::DeepStruct.new(instrumentation: 'listener.process_batch'),
                     Phobos::DeepStruct.new(instrumentation: 'foo.counter_only')])
      end

      it 'parses histograms' do
        config = subject.fetch(path)
        expect(config.histograms)
          .to match([Phobos::DeepStruct.new(instrumentation: 'listener.process_message',
                                            bucket_name: 'message'),
                     Phobos::DeepStruct.new(instrumentation: 'listener.process_batch',
                                            bucket_name: 'batch')])
      end

      it 'parses buckets' do
        config = subject.fetch(path)
        expect(config.buckets)
          .to match([Phobos::DeepStruct.new(name: 'message',
                                            bins: [5, 10, 25, 50, 100, 250, 500,
                                                   750, 1000, 2500, 5000]),
                     Phobos::DeepStruct.new(name: 'batch',
                                            bins: [100, 250, 500, 750, 1000, 2500,
                                                   5000, 10_000, 15_000])])
      end
    end
  end
end
