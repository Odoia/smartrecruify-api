# frozen_string_literal: true

module Employment
  module Experiences
    # app/services/employment/experiences/find.rb
    class Find
      def initialize(user:, id:, employment_record_id: nil)
        @user = user
        @id   = id
        @employment_record_id = employment_record_id
      end

      def call
        scope = ::EmploymentExperience
                  .joins(:employment_record)
                  .where(employment_records: { user_id: @user.id })
                  .where(employment_experiences: { id: @id })

        scope = scope.where(employment_experiences: { employment_record_id: @employment_record_id }) if @employment_record_id.present?

        scope.first! # levanta RecordNotFound se não achar
      end
    end
  end
end
