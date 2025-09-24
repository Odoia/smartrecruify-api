# frozen_string_literal: true

module Employment
  module Experiences
    class Destroy
      def initialize(experience:)
        @experience = experience
      end

      def call
        @experience.destroy!
        { ok: true }
      end
    end
  end
end
