# frozen_string_literal: true
module Importers
  module Pdf
    class DetectKind
      # Returns :linkedin, :cv, or :unknown based on simple heuristics.
      def self.call(text:)
        s = text.to_s.downcase
        return :linkedin if linkedin_like?(s)
        return :cv if cv_like?(s)
        :unknown
      end

      def self.linkedin_like?(s)
        # Typical LinkedIn export hints
        s.include?("www.linkedin.com/") ||
          s.include?("top skills") ||
          s.include?("experience") && s.include?("education") && s.include?("skills")
      end

      def self.cv_like?(s)
        # Very weak heuristic; you can enhance as you meet more samples
        s.include?("curriculum vitae") || s.include?("resume") || s.include?("objective")
      end
    end
  end
end
