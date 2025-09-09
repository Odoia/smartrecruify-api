# app/services/education/education_records/destroy.rb
module Education
  module EducationRecords
    class Destroy
      # Deletes a formal education record
      def self.call(record:)
        record.destroy!
      end
    end
  end
end
