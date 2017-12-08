# frozen_string_literal: true

module PhobosPrometheus
  # Collector houses common metrics code
  module Collector
    EVENT_LABEL_BUILDER = proc do |event|
      {
        topic:    event.payload[:topic],
        group_id: event.payload[:group_id],
        handler:  event.payload[:handler]
      }
    end
  end
end
