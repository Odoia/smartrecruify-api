# app/services/education/education_records/update.rb
module Education
  module EducationRecords
    class Update
      # Updates a formal education record
      def self.call(record:, params:)
        record.update!(params)
        record
      end
    end
  end
end
