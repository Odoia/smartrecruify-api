# frozen_string_literal: true
module Importers
  module Pdf
    class Validate
      Result = Struct.new(:ok, :reasons, keyword_init: true)

      # Cheap checks: mime type, size, can open, has minimum text length, contains any hint section
      def self.call(file:)
        reasons = []
        content_type = (file.content_type || "").downcase
        reasons << "not_pdf" unless content_type.include?("pdf")

        if file.respond_to?(:size)
          reasons << "empty_file" if file.size.to_i <= 0
        end

        # Light attempt to open & fetch some text
        begin
          text = Importers::Pdf::ExtractText.call(file: file, safe: true).raw_text.to_s
          reasons << "no_text_extracted" if text.strip.empty?
          # A few section hints typical of LinkedIn/CV PDFs
          unless text =~ /(experience|education|skills|summary|contact)/i
            reasons << "missing_linkedin_or_cv_sections"
          end
        rescue => e
          reasons << "open_failed: #{e.message}"
        end

        Result.new(ok: reasons.empty?, reasons: reasons)
      end
    end
  end
end
