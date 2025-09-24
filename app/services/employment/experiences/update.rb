# frozen_string_literal: true

module Employment
  module Experiences
    class Update
      def initialize(experience:, params:)
        @experience = experience
        @params     = params || {}
      end

      def call
        @experience.update!(@params)
        @experience
      end
    end
  end
end
