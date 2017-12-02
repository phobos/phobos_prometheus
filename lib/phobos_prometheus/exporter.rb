require 'sinatra/base'
require 'prometheus/client'
require 'prometheus/client/formats/text'

module PhobosPrometheus
  # Exporter is a Rack application that provides a Prometheus HTTP exposition
  # endpoint.
  class Exporter < Sinatra::Base
    attr_reader :registry

    FORMATS  = [Prometheus::Client::Formats::Text].freeze
    FALLBACK = Prometheus::Client::Formats::Text

    def initialize(options = {})
      super
      @registry = options[:registry] || Prometheus::Client.registry
      @acceptable = build_dictionary(FORMATS, FALLBACK)
    end

    get '/' do
      format = negotiate(env, @acceptable)
      format ? respond_with(format) : not_acceptable(FORMATS)
    end

    private

    def negotiate(env, formats)
      parse(env.fetch('HTTP_ACCEPT', '*/*')).each_entry do |content_type, _|
        return formats[content_type] if formats.key?(content_type)
      end

      nil
    end

    def parse(header)
      header.split(/\s*,\s*/).map do |type|
        attributes = type.split(/\s*;\s*/)
        quality = extract_quality(attributes)

        [attributes.join('; '), quality]
      end.sort_by(&:last).reverse
    end

    def extract_quality(attributes, default = 1.0)
      quality = default

      attributes.delete_if do |attr|
        quality = attr.split('q=').last.to_f if attr.start_with?('q=')
      end

      quality
    end

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

    def build_dictionary(formats, fallback)
      formats.each_with_object('*/*' => fallback) do |format, memo|
        memo[format::CONTENT_TYPE] = format
        memo[format::MEDIA_TYPE] = format
      end
    end
  end
end
