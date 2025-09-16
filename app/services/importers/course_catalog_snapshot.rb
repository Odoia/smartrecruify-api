# frozen_string_literal: true
module Importers
  class CourseCatalogSnapshot
    DEFAULT_LIMIT = 250

    def self.call(limit: DEFAULT_LIMIT)
      rows = Course.select(:id, :name, :provider, :category, :hours)
                   .order(Arel.sql("LOWER(provider), LOWER(name)"))
                   .limit(limit)
      rows.map { |c|
        # formato estável pro prompt: course_id | provider | name | category | hours
        [c.id, scrub(c.provider), scrub(c.name), scrub(c.category), c.hours.to_i].join(" | ")
      }.join("\n")
    end

    def self.scrub(s) = s.to_s.strip.gsub("|", " ")
  end
end
