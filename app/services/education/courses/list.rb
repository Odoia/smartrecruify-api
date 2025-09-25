# frozen_string_literal: true

module Education
  module Courses
    # app/services/education/courses/list.rb
    class List
      def initialize(limit: 50, filters: {})
        @limit   = Integer(limit).clamp(1, 500)
        @filters = filters || {}
      end

      def call
        scope = ::Course.all

        if filters[:search].present?
          like = "%#{ActiveRecord::Base.sanitize_sql_like(filters[:search])}%"
          scope = scope.where("provider ILIKE ? OR name ILIKE ?", like, like)
        end

        if filters[:category].present?
          scope = scope.where(category: filters[:category])
        end

        scope
          .order(Arel.sql("LOWER(provider), LOWER(name)"))
          .limit(limit)
          .map { |c| { id: c.id, provider: c.provider, name: c.name, category: c.category } }
      end

      private

      attr_reader :limit, :filters
    end
  end
end
