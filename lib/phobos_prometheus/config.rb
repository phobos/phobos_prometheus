# frozen_string_literal: true

module PhobosPrometheus
  # Collector houses common metrics code
  module Config
    ROOT_MISSING_COLLECTORS = 'Histograms and counters are not configured, ' \
                              'metrics will not be recorded'
    def self.fetch(path)
      config = read_config(path)
      validate_config(config)
    end

    def self.read_config(path)
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

    def self.validate_config(config)
      ensure_collectors(config) || Phobos.logger.warn(message: ROOT_MISSING_COLLECTORS)
      config
    end

    def self.ensure_collectors(config)
      config.counters && config.histograms
    end
  end
end
