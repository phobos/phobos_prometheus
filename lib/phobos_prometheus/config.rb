# frozen_string_literal: true

module PhobosPrometheus
  # Collector houses common metrics code
  module Config
    def self.fetch(path)
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
  end
end
