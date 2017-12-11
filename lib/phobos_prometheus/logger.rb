# frozen_string_literal: true

module PhobosPrometheus
  # Logger module
  module Logger
    def log_info(message)
      Phobos.logger.info(Hash(message: message))
    end

    def log_warn(message)
      Phobos.logger.warn(Hash(message: message))
    end

    def log_error(message)
      Phobos.logger.error(Hash(message: message))
    end
  end
end
