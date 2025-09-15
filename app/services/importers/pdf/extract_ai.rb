# frozen_string_literal: true
# Default extractor when no specialization exists.
module Importers
  module Pdf
    class ExtractAi
      Result = Struct.new(:extracted, :confidence, :missing_fields, keyword_init: true)

      # NOTE: Replace this with your LLM client. Keep the JSON schema strict.
      def self.call(text:)
        # Minimal dumb fallback: just stub a shape.
        extracted = {
          basic: { full_name: nil, headline: nil, email: nil, phone: nil, linkedin_url: nil, github_url: nil },
          employment: [],
          education: [],
          skills: []
        }
        Result.new(extracted: extracted, confidence: 0.0, missing_fields: %w[full_name])
      end
    end
  end
end
