# frozen_string_literal: true
# LinkedIn-specific extractor using LLM prompts tuned to the LinkedIn PDF layout.
module Importers
  module Linkedin
    module Pdf
      class ExtractAi
        Result = Struct.new(:extracted, :confidence, :missing_fields, keyword_init: true)

        def self.call(text:)
          # TODO: replace with your LLM client.
          # The goal is to produce the same JSON shape as the generic fallback,
          # but with much higher recall/precision for LinkedIn exports.
          extracted = {
            basic: { full_name: nil, headline: nil, email: nil, phone: nil, linkedin_url: nil, github_url: nil },
            employment: [], education: [], skills: []
          }
          Result.new(extracted: extracted, confidence: 0.8, missing_fields: [])
        end
      end
    end
  end
end
