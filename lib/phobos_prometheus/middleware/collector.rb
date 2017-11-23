require 'prometheus/client'

module PhobosPrometheus
  module Middleware
    # Rack middleware for Phobos, collecting prometheus metrics
    class Collector
      attr_reader :app, :registry

      def initialize(app, options = {})
        @app = app
        @registry = options[:registry] || Prometheus::Client.registry
        @metrics_prefix = options[:metrics_prefix] || 'phobos_client'
        # @counter_lb = options[:counter_label_builder] || COUNTER_LB
        # @duration_lb = options[:duration_label_builder] || DURATION_LB

        puts "===== PhobosPrometheus::Middleware::Collector, app = #{app}"
        Phobos::Instrumentation.subscribe('listener.start') do |event|
          puts "===== PhobosPrometheus::Middleware::Collector, event.payload = #{event.payload}"
        end
      end
    end
  end
end
