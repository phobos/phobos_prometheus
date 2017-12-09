# frozen_string_literal: true

module PhobosPrometheus
  # Config validates and parses configuration yml
  class ConfigParser
    include Logger
    attr_accessor :config

    ROOT_MISSING_COLLECTORS = 'Histograms and counters are not configured, ' \
                              'metrics will not be recorded'
    ROOT_INVALID_KEY = 'Invalid configuration option detected, ignoring'
    ROOT_KEYS = [:metrics_prefix, :counters, :histograms, :buckets].freeze

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
      ensure_collectors? || log_warn(ROOT_MISSING_COLLECTORS)
      only_valid_root_keys? || log_warn(ROOT_INVALID_KEY)
      config
    end

    def ensure_collectors?
      @config.counters || @config.histograms
    end

    def only_valid_root_keys?
      @config.to_h.keys.all? { |key| ROOT_KEYS.include?(key) }
    end
  end
end
