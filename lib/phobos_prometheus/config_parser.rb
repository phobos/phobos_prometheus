# frozen_string_literal: true

module PhobosPrometheus
  # Validate Counters
  class CountersValidator
    include Logger
    COUNTER_INSTRUMENTATION_MISSING = 'Missing required key :instrumentation for counter'
    COUNTER_INVALID_KEY = 'Invalid configuration option detected at counter level, ignoring'
    COUNTER_KEYS = [:instrumentation].freeze

    def initialize(counters)
      @counters = counters
    end

    def validate
      @counters.map do |counter|
        validate_counter(counter)
      end
    end

    def validate_counter(counter)
      Helper.assert_required_key(counter, :instrumentation) || \
        Helper.fail_config(COUNTER_INSTRUMENTATION_MISSING)
      Helper.check_invalid_keys(COUNTER_KEYS, counter) || \
        log_warn(COUNTER_INVALID_KEY)
    end
  end

  # Validate Histograms
  class HistogramsValidator
    include Logger
    HISTOGRAM_INSTRUMENTATION_MISSING = 'Missing required key :instrumentation for histogram'
    HISTOGRAM_BUCKET_NAME_MISSING = 'Missing required key :bucket_name for histogram'
    HISTOGRAM_INVALID_BUCKET = 'Invalid bucket reference specified for histogram'
    HISTOGRAM_INVALID_KEY = 'Invalid configuration option detected at histogram level, ignoring'
    HISTOGRAM_KEYS = [:instrumentation, :bucket_name].freeze

    def initialize(histograms, buckets)
      @histograms = histograms
      @buckets = buckets
    end

    def validate
      @histograms.map do |histogram|
        validate_histogram(histogram)
      end
    end

    def validate_histogram(histogram)
      Helper.assert_required_key(histogram, :instrumentation) || \
        Helper.fail_config(HISTOGRAM_INSTRUMENTATION_MISSING)
      Helper.assert_required_key(histogram, :bucket_name) || \
        Helper.fail_config(HISTOGRAM_BUCKET_NAME_MISSING)
      assert_bucket_exists(histogram['bucket_name']) || Helper.fail_config(HISTOGRAM_INVALID_BUCKET)
      Helper.check_invalid_keys(HISTOGRAM_KEYS, histogram) || \
        log_warn(HISTOGRAM_INVALID_KEY)
    end

    def assert_bucket_exists(name)
      @buckets.any? { |key| key.name == name }
    end
  end

  # Validate buckets
  class BucketsValidator
    include Logger
    BUCKET_NAME_MISSING = 'Missing required key :name for bucket'
    BUCKET_BINS_MISSING = 'Missing required key :bins for bucket'
    BUCKET_BINS_EMPTY = 'Bucket config bad, bins are empty'
    BUCKET_INVALID_KEY = 'Invalid configuration option detected at bucket level, ignoring'
    BUCKET_KEYS = [:name, :bins].freeze

    def initialize(buckets)
      @buckets = buckets
    end

    def validate
      @buckets.map do |bucket|
        validate_bucket(bucket)
      end
    end

    def validate_bucket(bucket)
      Helper.assert_required_key(bucket, :name) || Helper.fail_config(BUCKET_NAME_MISSING)
      Helper.assert_required_key(bucket, :bins) || Helper.fail_config(BUCKET_BINS_MISSING)
      Helper.assert_array_of_type(bucket, :bins, Integer) || Helper.fail_config(BUCKET_BINS_EMPTY)
      Helper.check_invalid_keys(BUCKET_KEYS, bucket) || \
        log_warn(BUCKET_INVALID_KEY)
    end
  end

  # Validate gauges
  class GaugesValidator
    include Logger
    GAUGE_LABEL_MISSING = 'Missing required key :label for gauge'
    GAUGE_INCREMENT_MISSING = 'Missing required key :increment for gauge'
    GAUGE_DECREMENT_MISSING = 'Missing required key :decrement for gauge'
    GAUGE_INVALID_KEY = 'Invalid configuration option detected at gauge level, ignoring'
    GAUGE_KEYS = [:name, :increment, :decrement].freeze

    def initialize(gauges)
      @gauges = gauges
    end

    def validate
      @gauges.map do |gauge|
        validate_gauge(gauge)
      end
    end

    def validate_gauge(gauge)
      Helper.assert_required_key(gauge, :label) || Helper.fail_config(GAUGE_LABEL_MISSING)
      Helper.assert_required_key(gauge, :increment) || Helper.fail_config(GAUGE_INCREMENT_MISSING)
      Helper.assert_required_key(gauge, :decrement) || Helper.fail_config(GAUGE_DECREMENT_MISSING)
      Helper.check_invalid_keys(GAUGE_KEYS, gauge) || \
        log_warn(GAUGE_INVALID_KEY)
    end
  end

  # Helper for operations not dependent on instance state
  module Helper
    def self.read_config(path)
      Phobos::DeepStruct.new(
        YAML.safe_load(
          ERB.new(
            File.read(File.expand_path(path))
          ).result
        )
      )
    end

    def self.assert_required_key(metric, required)
      metric.keys.any? { |key| key.to_sym == required }
    end

    def self.assert_array_of_type(metric, key, type)
      ary = metric[key.to_s]
      ary.is_a?(Array) && \
        ary.all? { |value| value.class == type }
    end

    def self.fail_config(message)
      raise(InvalidConfigurationError, message)
    end

    def self.check_invalid_keys(keys, metric)
      metric.keys.all? { |key| keys.include?(key.to_sym) }
    end
  end

  # Config validates and parses configuration yml
  class ConfigParser
    include Logger
    attr_reader :config

    ROOT_MISSING_COLLECTORS = 'No histograms, gauges nor counters are configured. ' \
                              'Metrics will not be recorded'
    ROOT_INVALID_KEY = 'Invalid configuration option detected at root level, ignoring'
    ROOT_KEYS = [:metrics_prefix, :counters, :histograms, :buckets, :gauges].freeze

    def initialize(path)
      @config = Helper.read_config(path)
      validate_config
      @config.counters = [] unless @config.counters
      @config.histograms = [] unless @config.histograms
      @config.gauges = [] unless @config.gauges
      @config.freeze
    end

    def validate_config
      validate_root
      validate_counters
      validate_histograms
      validate_buckets
      validate_gauges
    end

    def validate_root
      assert_required_root_keys
      Helper.check_invalid_keys(ROOT_KEYS, @config.to_h) || \
        log_warn(ROOT_INVALID_KEY)
    end

    def validate_counters
      CountersValidator.new(@config.to_h[:counters] || []).validate
    end

    def validate_histograms
      HistogramsValidator.new(@config.to_h[:histograms] || [], @config.buckets).validate
    end

    def validate_buckets
      BucketsValidator.new(@config.to_h[:buckets] || []).validate
    end

    def validate_gauges
      GaugesValidator.new(@config.to_h[:gauges] || []).validate
    end

    def assert_required_root_keys
      @config.counters || @config.histograms || @config.gauges || \
        log_warn(ROOT_MISSING_COLLECTORS)
    end
  end
end
