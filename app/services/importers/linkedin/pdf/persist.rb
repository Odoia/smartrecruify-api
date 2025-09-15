# frozen_string_literal: true
# Writes into your domain models (education_records, employment_records/experiences, skills, etc.)
module Importers
  module Linkedin
    module Pdf
      class Persist
        Result = Struct.new(:summary, keyword_init: true)

        def self.call(user:, data:)
          created = { employment: 0, education: 0, skills: 0 }
          updated = {}

          # Basic profile could update user record if you want
          basic = data[:basic] || {}

          (data[:education] || []).each do |e|
            # Example upsert. Adjust to your models/validations.
            rec = user.education_records.where(
              institution_name: e[:institution_name],
              program_name: e[:program_name]
            ).first_or_initialize
            rec.degree_level    = e[:degree_level]
            rec.started_on      = e[:started_on]
            rec.ended_on        = e[:ended_on]
            rec.status          = e[:status]
            rec.save!
            created[:education] += (rec.previous_changes.key?("id") ? 1 : 0)
          end

          (data[:employment] || []).each do |job|
            # If you have employment_records + experiences, adapt accordingly
            rec = user.employment_records.where(company_name: job[:company_name]).first_or_initialize
            rec.save! if rec.new_record?

            exp = rec.employment_experiences.where(job_title: job[:job_title], started_on: job[:started_on]).first_or_initialize
            exp.ended_on   = job[:ended_on]
            exp.current    = job[:current]
            exp.location   = job[:location]
            exp.description= job[:description]
            exp.save!
            created[:employment] += (exp.previous_changes.key?("id") ? 1 : 0)
          end

          (data[:skills] || []).each do |s|
            name = s[:name].to_s.strip
            next if name.blank?
            # Example: user.skills << ... or upsert in join table
            # created[:skills] += 1 if newly created
          end

          Result.new(summary: { created: created, updated: updated })
        end
      end
    end
  end
end
