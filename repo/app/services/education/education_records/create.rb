# app/services/education/education_records/create.rb
module Education
  module EducationRecords
    class Create
      # Creates a formal education record under a profile
      def self.call(profile:, params:)
        record = profile.education_records.new(params)
        record.save!
        record
      end
    end
  end
end
