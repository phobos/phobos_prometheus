# frozen_string_literal: true

RSpec.describe PhobosPrometheus::ConfigParser do
  let(:registry) { Prometheus::Client::Registry.new }
  before :each do
    allow(Prometheus::Client).to receive(:registry).and_return(registry)
  end

  def expect_log(level, message)
    expect(Phobos.logger)
      .to receive(level)
      .with(Hash(message: message))
  end

  describe '.config' do
    context 'with valid config' do
      let(:path) { './spec/fixtures/phobos_prometheus.yml' }
      let(:config) { described_class.new(path).config }

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

      it 'parses gauges' do
        expect(config.gauges)
          .to match([Phobos::DeepStruct.new(label: 'number_of_handlers',
                                            decrement: 'listener.stop_handler',
                                            increment: 'listener.start_handler')])
      end
    end

    context 'with invalid config', :with_logger, :clear_config do
      describe 'for root' do
        it 'logs warning about missing counters and histograms' do
          expect_log(:warn, described_class::ROOT_MISSING_COLLECTORS)
          PhobosPrometheus.configure('spec/fixtures/config/root/missing.yml')
          expect { PhobosPrometheus.subscribe }.to_not raise_error
          expect(PhobosPrometheus.metrics).to be_empty
        end

        it 'logs warning about having invalid keys' do
          expect_log(:warn, described_class::ROOT_INVALID_KEY)
          PhobosPrometheus.configure('spec/fixtures/config/root/invalid_keys.yml')
          expect { PhobosPrometheus.subscribe }.to_not raise_error
          expect(PhobosPrometheus.metrics).to match([PhobosPrometheus::Collector::Counter])
        end
      end

      describe 'for counters' do
        it 'raises error when missing instrumentation' do
          expect do
            PhobosPrometheus.configure('spec/fixtures/config/counters/missing_instrumentation.yml')
          end.to raise_error(
            PhobosPrometheus::InvalidConfigurationError,
            PhobosPrometheus::CountersValidator::COUNTER_INSTRUMENTATION_MISSING
          )
        end

        it 'logs warning about having invalid keys' do
          expect_log(:warn, PhobosPrometheus::CountersValidator::COUNTER_INVALID_KEY)
          PhobosPrometheus.configure('spec/fixtures/config/counters/invalid_keys.yml')
          expect { PhobosPrometheus.subscribe }.to_not raise_error
          expect(PhobosPrometheus.metrics).to match([PhobosPrometheus::Collector::Counter])
        end
      end

      describe 'for histograms' do
        it 'raises error when missing instrumentation' do
          expect do
            PhobosPrometheus.configure(
              'spec/fixtures/config/histograms/missing_instrumentation.yml'
            )
          end.to raise_error(
            PhobosPrometheus::InvalidConfigurationError,
            PhobosPrometheus::HistogramsValidator::HISTOGRAM_INSTRUMENTATION_MISSING
          )
        end

        it 'raises error when missing bucket_name' do
          expect do
            PhobosPrometheus.configure('spec/fixtures/config/histograms/missing_bucket_name.yml')
          end.to raise_error(
            PhobosPrometheus::InvalidConfigurationError,
            PhobosPrometheus::HistogramsValidator::HISTOGRAM_BUCKET_NAME_MISSING
          )
        end

        it 'raises error when having invalid bucket_name reference' do
          expect do
            PhobosPrometheus.configure(
              'spec/fixtures/config/histograms/missing_valid_bucket_reference.yml'
            )
          end.to raise_error(
            PhobosPrometheus::InvalidConfigurationError,
            PhobosPrometheus::HistogramsValidator::HISTOGRAM_INVALID_BUCKET
          )
        end

        it 'logs warning about having invalid keys' do
          expect_log(:warn, PhobosPrometheus::HistogramsValidator::HISTOGRAM_INVALID_KEY)
          PhobosPrometheus.configure('spec/fixtures/config/histograms/invalid_keys.yml')
          expect { PhobosPrometheus.subscribe }.to_not raise_error
          expect(PhobosPrometheus.metrics).to match([PhobosPrometheus::Collector::Histogram])
        end
      end

      describe 'for buckets' do
        it 'raises error when missing name' do
          expect do
            PhobosPrometheus.configure(
              'spec/fixtures/config/buckets/missing_name.yml'
            )
          end.to raise_error(
            PhobosPrometheus::InvalidConfigurationError,
            PhobosPrometheus::BucketsValidator::BUCKET_NAME_MISSING
          )
        end

        it 'raises error when missing bins' do
          expect do
            PhobosPrometheus.configure(
              'spec/fixtures/config/buckets/missing_bins.yml'
            )
          end.to raise_error(
            PhobosPrometheus::InvalidConfigurationError,
            PhobosPrometheus::BucketsValidator::BUCKET_BINS_MISSING
          )
        end

        it 'raises error when bins are wrong type' do
          expect do
            PhobosPrometheus.configure(
              'spec/fixtures/config/buckets/bins_wrong_type.yml'
            )
          end.to raise_error(
            PhobosPrometheus::InvalidConfigurationError,
            PhobosPrometheus::BucketsValidator::BUCKET_BINS_EMPTY
          )
        end

        it 'raises error when bins are empty' do
          expect do
            PhobosPrometheus.configure(
              'spec/fixtures/config/buckets/bins_empty.yml'
            )
          end.to raise_error(
            PhobosPrometheus::InvalidConfigurationError,
            PhobosPrometheus::BucketsValidator::BUCKET_BINS_EMPTY
          )
        end

        it 'logs warning about having invalid keys' do
          expect_log(:warn, PhobosPrometheus::BucketsValidator::BUCKET_INVALID_KEY)
          PhobosPrometheus.configure('spec/fixtures/config/buckets/invalid_keys.yml')
          expect { PhobosPrometheus.subscribe }.to_not raise_error
          expect(PhobosPrometheus.metrics).to match([PhobosPrometheus::Collector::Histogram])
        end
      end

      describe 'for gauges' do
        it 'raises error when missing label' do
          expect do
            PhobosPrometheus.configure('spec/fixtures/config/gauges/missing_label.yml')
          end.to raise_error(
            PhobosPrometheus::InvalidConfigurationError,
            PhobosPrometheus::GaugesValidator::GAUGE_LABEL_MISSING
          )
        end

        it 'raises error when missing increment' do
          expect do
            PhobosPrometheus.configure('spec/fixtures/config/gauges/missing_increment.yml')
          end.to raise_error(
            PhobosPrometheus::InvalidConfigurationError,
            PhobosPrometheus::GaugesValidator::GAUGE_INCREMENT_MISSING
          )
        end

        it 'raises error when missing decrement' do
          expect do
            PhobosPrometheus.configure('spec/fixtures/config/gauges/missing_decrement.yml')
          end.to raise_error(
            PhobosPrometheus::InvalidConfigurationError,
            PhobosPrometheus::GaugesValidator::GAUGE_DECREMENT_MISSING
          )
        end

        it 'logs warning about having invalid keys' do
          expect_log(:warn, PhobosPrometheus::GaugesValidator::GAUGE_INVALID_KEY)
          PhobosPrometheus.configure('spec/fixtures/config/gauges/invalid_keys.yml')
          expect { PhobosPrometheus.subscribe }.to_not raise_error
          expect(PhobosPrometheus.metrics).to match([PhobosPrometheus::Collector::Gauge])
        end
      end
    end
  end
end
