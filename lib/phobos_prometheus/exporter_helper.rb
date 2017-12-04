module PhobosPrometheus
  # Helper for Exporter
  class ExporterHelper
    class << self
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

      def build_dictionary(formats, fallback)
        formats.each_with_object('*/*' => fallback) do |format, memo|
          memo[format::CONTENT_TYPE] = format
          memo[format::MEDIA_TYPE] = format
        end
      end
    end
  end
end
