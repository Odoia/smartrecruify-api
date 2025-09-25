# frozen_string_literal: true

module Education
  module Profiles
    # app/services/education/profiles/load.rb
    class Load
      def initialize(user:)
        @user = user
      end

      def call
        @user.education_profile || @user.create_education_profile!
      end

      private

      attr_reader :user
    end
  end
end
