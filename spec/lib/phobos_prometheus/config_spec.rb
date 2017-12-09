# frozen_string_literal: true

RSpec.describe PhobosPrometheus::Config do
  def expect_log(level, message)
    expect(Phobos.logger)
      .to receive(level)
      .with(Hash(message: message))
  end

  describe '.fetch' do
    context 'with valid config' do
      let(:path) { './spec/fixtures/phobos_prometheus.yml' }
      let(:config) { described_class.fetch(path) }

      it 'parses metrics_prefix' do
        expect(config.metrics_prefix).to eq('phobos_app')
      end

      it 'parses counters' do
        expect(config.counters)
          .to match([Phobos::DeepStruct.new(instrumentation: 'listener.process_message'),
                     Phobos::DeepStruct.new(instrumentation: 'listener.process_batch'),
                     Phobos::DeepStruct.new(instrumentation: 'foo.counter_only')])
      end

      it 'parses histograms' do
        expect(config.histograms)
          .to match([Phobos::DeepStruct.new(instrumentation: 'listener.process_message',
                                            bucket_name: 'message'),
                     Phobos::DeepStruct.new(instrumentation: 'listener.process_batch',
                                            bucket_name: 'batch')])
      end

      it 'parses buckets' do
        expect(config.buckets)
          .to match([Phobos::DeepStruct.new(name: 'message',
                                            bins: [5, 10, 25, 50, 100, 250, 500,
                                                   750, 1000, 2500, 5000]),
                     Phobos::DeepStruct.new(name: 'batch',
                                            bins: [100, 250, 500, 750, 1000, 2500,
                                                   5000, 10_000, 15_000])])
      end
    end

    context 'with invalid config', :with_logger, :clear_config do
      describe 'for root' do
        it 'missing counters and histograms' do
          expect_log(:warn, PhobosPrometheus::Config::ROOT_MISSING_COLLECTORS)
          PhobosPrometheus.configure('spec/fixtures/config/root/missing.yml')
          expect { PhobosPrometheus.subscribe }.to_not raise_error
          expect(PhobosPrometheus.metrics).to be_empty
        end

        it 'invalid keys'
      end

      describe 'for counters' do
        it 'missing instrumentation'
        it 'invalid keys'
      end

      describe 'for histograms' do
        it 'missing instrumentation'
        it 'missing bucket_name'
        it 'invalid bucket_name reference'
        it 'invalid keys'
      end

      describe 'for buckets' do
        it 'invalid keys'
        it 'missing bins'
        it 'missing name'
      end
    end
  end
end
