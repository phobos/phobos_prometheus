require 'prometheus/client'

module PhobosPrometheus
  module Middleware
    # desc
    class Collector
      def initialize(app)
        puts "=============== PhobosPrometheus::Middleware::Collector, app = #{app}"
        Phobos::Instrumentation.subscribe('listener.start') do |event|
          puts "=============== PhobosPrometheus::Middleware::Collector, event.payload = #{event.payload}"
        end
      end
    end
  end
end
