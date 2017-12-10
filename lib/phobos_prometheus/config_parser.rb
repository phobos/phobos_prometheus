# frozen_string_literal: true

module PhobosPrometheus
  # Config validates and parses configuration yml
  class ConfigParser
    include Logger
    attr_accessor :config

    ROOT_MISSING_COLLECTORS = 'Histograms and counters are not configured, ' \
                              'metrics will not be recorded'
    ROOT_INVALID_KEY = 'Invalid configuration option detected at root level, ignoring'
    COUNTER_MISSING_REQUIRED_KEY = 'Missing required key :instrumentation for counter'
    COUNTER_INVALID_KEY = 'Invalid configuration option detected at counter level, ignoring'
    HISTOGRAM_MISSING_REQUIRED_KEY1 = 'Missing required key :instrumentation for histogram'
    HISTOGRAM_MISSING_REQUIRED_KEY2 = 'Missing required key :bucket_name for histogram'
    HISTOGRAM_INVALID_BUCKET = 'Invalid bucket reference specified for histogram'
    HISTOGRAM_INVALID_KEY = 'Invalid configuration option detected at histogram level, ignoring'
    BUCKET_NAME_MISSING = 'Missing required key :name for bucket'
    BUCKET_BINS_MISSING = 'Missing required key :bins for bucket'
    BUCKET_BINS_NOT_ARRAY = 'Bucket config bad, :bins should be an array'
    BUCKET_BINS_EMPTY = 'Bucket config bad, bins are empty'
    BUCKET_INVALID_KEY = 'Invalid configuration option detected at bucket level, ignoring'
    ROOT_KEYS = [:metrics_prefix, :counters, :histograms, :buckets].freeze
    HISTOGRAM_KEYS = [:instrumentation, :bucket_name].freeze
    COUNTER_KEYS = [:instrumentation].freeze
    BUCKET_KEYS = [:name, :bins].freeze

    def initialize(path)
      @config = read_config(path)
      validate_config
    end

    def read_config(path)
      Phobos::DeepStruct.new(
        YAML.safe_load(
          ERB.new(
            File.read(
              File.expand_path(path)
            )
          ).result
        )
      )
    end

    def validate_config
      validate_root
      validate_counters
      validate_histograms
      validate_buckets
      config
    end

    def validate_root
      assert_required_root_keys
      check_invalid_keys(ROOT_KEYS, @config.to_h, ROOT_INVALID_KEY)
    end

    def validate_counters
      counters = @config.to_h[:counters]
      counters&.map do |counter|
        assert_required_key(counter, :instrumentation, COUNTER_MISSING_REQUIRED_KEY)
        check_invalid_keys(COUNTER_KEYS, counter, COUNTER_INVALID_KEY)
      end
    end

    def validate_histograms
      histograms = @config.to_h[:histograms]
      histograms&.map do |histogram|
        assert_required_key(histogram, :instrumentation, HISTOGRAM_MISSING_REQUIRED_KEY1)
        assert_required_key(histogram, :bucket_name, HISTOGRAM_MISSING_REQUIRED_KEY2)
        assert_bucket_exists(histogram['bucket_name'], HISTOGRAM_INVALID_BUCKET)
        check_invalid_keys(HISTOGRAM_KEYS, histogram, HISTOGRAM_INVALID_KEY)
      end
    end

    def validate_buckets
      buckets = @config.to_h[:buckets]
      buckets&.map do |bucket|
        assert_required_key(bucket, :name, BUCKET_NAME_MISSING)
        assert_required_key(bucket, :bins, BUCKET_BINS_MISSING)
        assert_type(bucket, :bins, Array, BUCKET_BINS_NOT_ARRAY)
        assert_array_of_type(bucket, :bins, Integer, BUCKET_BINS_EMPTY)
        check_invalid_keys(BUCKET_KEYS, bucket, BUCKET_INVALID_KEY)
      end
    end

    def assert_required_root_keys
      @config.counters || @config.histograms || \
        log_warn(ROOT_MISSING_COLLECTORS)
    end

    def check_invalid_keys(keys, metric, msg)
      metric.keys.all? { |key| keys.include?(key.to_sym) } || \
        log_warn(msg)
    end

    def assert_required_key(metric, required, msg)
      metric.keys.any? { |key| key.to_sym == required } || \
        raise(InvalidConfigurationError, msg)
    end

    def assert_bucket_exists(name, msg)
      @config.buckets.any? { |key| key.name == name } || \
        raise(InvalidConfigurationError, msg)
    end

    def assert_type(metric, key, type, msg)
      metric[key.to_s].class == type || \
        raise(InvalidConfigurationError, msg)
    end

    def assert_array_of_type(metric, key, type, msg)
      metric[key.to_s].all? { |value| value.class == type } || \
        raise(InvalidConfigurationError, msg)
    end
  end
end
