# frozen_string_literal: true

# app/services/education/language_skills/list.rb
module Education
  module LanguageSkills
    class List
      def initialize(profile:, filters: nil)
        @profile = profile
        @filters = (filters || {}).to_h.symbolize_keys
      end

      def call
        scope   = profile.language_skills
        filters = @filters

        scope = scope.where(language: filters[:language]) if filters[:language].present?
        scope = scope.where(level:    filters[:level])    if filters[:level].present?

        if filters[:query].present?
          sanitized_query = "%#{ActiveRecord::Base.sanitize_sql_like(filters[:query].to_s)}%"
          scope = scope.where("certificate_name ILIKE ? OR certificate_score ILIKE ?", sanitized_query, sanitized_query)
        end

        scope = case filters[:order].to_s
        when "language_asc"
          scope.order(language: :asc, level: :desc, created_at: :desc)
        when "created_desc"
          scope.order(created_at: :desc)
        else
          scope.order(language: :asc, level: :desc, created_at: :desc)
        end

        if filters[:page].present? || filters[:per_page].present?
          page     = filters[:page].to_i
          per_page = filters[:per_page].to_i
          page     = 1   if page <= 0
          per_page = 50  if per_page <= 0
          per_page = 200 if per_page > 200

          scope = scope.limit(per_page).offset((page - 1) * per_page)
        end

        scope
      end

      private

      attr_reader :profile, :filters
    end
  end
end
