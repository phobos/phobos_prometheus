# frozen_string_literal: true

module PhobosPrometheus
  # Exporter is a Rack application that provides a Prometheus HTTP exposition
  # endpoint.
  class Exporter < Sinatra::Base
    attr_reader :registry

    FORMATS  = [Prometheus::Client::Formats::Text].freeze
    FALLBACK = Prometheus::Client::Formats::Text

    def initialize
      super
      @registry = Prometheus::Client.registry
      @acceptable = ExporterHelper.build_dictionary(FORMATS, FALLBACK)
    end

    get '/' do
      format = ExporterHelper.negotiate(env, @acceptable)
      format ? respond_with(format) : not_acceptable(FORMATS)
    end

    private

    def respond_with(format)
      [
        200,
        { 'Content-Type' => format::CONTENT_TYPE },
        [format.marshal(@registry)]
      ]
    end

    def not_acceptable(formats)
      types = formats.map { |format| format::MEDIA_TYPE }

      [
        406,
        { 'Content-Type' => 'text/plain' },
        ["Supported media types: #{types.join(', ')}"]
      ]
    end
  end
end
