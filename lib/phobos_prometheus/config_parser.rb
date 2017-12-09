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
    HISTOGRAM_INVALID_KEY = 'Invalid configuration option detected at histogram level, ignoring'
    ROOT_KEYS = [:metrics_prefix, :counters, :histograms, :buckets].freeze
    HISTOGRAM_KEYS = [:instrumentation, :bucket_name].freeze
    COUNTER_KEYS = [:instrumentation].freeze

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
      config
    end

    def validate_root
      required_root_keys_present? || log_warn(ROOT_MISSING_COLLECTORS)
      all_root_keys_valid? || log_warn(ROOT_INVALID_KEY)
    end

    def required_root_keys_present?
      @config.counters || @config.histograms
    end

    def all_root_keys_valid?
      @config.to_h.keys.all? { |key| ROOT_KEYS.include?(key.to_sym) }
    end

    def validate_counters
      counters = @config.to_h[:counters]
      counters&.map do |counter|
        instrumentation_key_present?(counter, :instrumentation) ||
          raise(InvalidConfigurationError, COUNTER_MISSING_REQUIRED_KEY)
        all_keys_valid?(COUNTER_KEYS, counter) || log_warn(COUNTER_INVALID_KEY)
      end
    end

    def validate_histograms
      histograms = @config.to_h[:histograms]
      histograms&.map do |histogram|
        instrumentation_key_present?(histogram, :instrumentation) ||
          raise(InvalidConfigurationError, HISTOGRAM_MISSING_REQUIRED_KEY1)
        instrumentation_key_present?(histogram, :bucket_name) ||
          raise(InvalidConfigurationError, HISTOGRAM_MISSING_REQUIRED_KEY2)
        all_keys_valid?(HISTOGRAM_KEYS, histogram) || log_warn(HISTOGRAM_INVALID_KEY)
      end
    end

    def all_keys_valid?(keys, metric)
      metric.keys.all? { |key| keys.include?(key.to_sym) }
    end

    def instrumentation_key_present?(metric, required)
      metric.keys.any? { |key| key.to_sym == required }
    end
  end
end
