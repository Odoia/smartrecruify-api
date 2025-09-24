# frozen_string_literal: true

require "base64"

module Documents
  module Pdf
    class AiPromptBuilder
      def initialize(images:, user:, course_catalog: [], pages_count: nil, mode: :resume)
        @images          = Array(images)            # paths dos JPEGs
        @user            = user
        @course_catalog  = Array(course_catalog)
        @pages_count     = pages_count || @images.size
        @mode            = mode
      end

      # Retorna um Hash compatível com AiCaller (mode :vision):
      # {
      #   system: "...",
      #   user_text: "...",
      #   input: { images: [ "data:image/jpeg;base64,...", ... ] }
      # }
      def call
        {
          system: system_prompt,
          user_text: instruction_block.strip,
          input: { images: data_urls }
        }
      end

      private

      attr_reader :images, :user, :course_catalog, :pages_count, :mode

      def system_prompt
        <<~SYS
          You are a strict JSON generator and an expert resume/CV parser.
          You will receive 1..N page IMAGES of a document (PDF converted to JPEG).
          Your only job is to OCR the images carefully and return ONE single JSON object matching EXACTLY the schema and rules below.
          Do not include any explanations, comments, markdown, or code fences — return ONLY raw JSON.
        SYS
      end

      def schema_block
        <<~SCHEMA
          {
            "basic": {
              "full_name": string|null,
              "headline": string|null,
              "address": string|null,
              "phone": string|null,
              "email": string|null,
              "linkedin_url": string|null,
              "github_url": string|null
            },
            "education_records": [
              {
                "institution_name": string,
                "degree_level": string|null,
                "program_name": string|null,
                "started_on": string|null,
                "expected_end_on": string|null,
                "ended_on": string|null,
                "status": "completed"|"in_progress",
                "gpa": string|null,
                "transcript_url": string|null
              }
            ],
            "courses_mapped_to_catalog": [],
            "courses_to_create": [],
            "languages": [
              {
                "language": string,
                "proficiency": "A1"|"A2"|"B1"|"B2"|"C1"|"C2"|null
              }
            ],
            "employment": [
              {
                "company_name": string,
                "job_title": string,
                "started_on": string,
                "ended_on": string|null,
                "current": boolean,
                "location": string|null,
                "job_description": string|null,
                "responsibilities": string|null,
                "experiences": [
                  {
                    "title": string,
                    "description": string|null,
                    "impact": string|null,
                    "skills": [string],
                    "tools": [string],
                    "tags": [string],
                    "metrics": object,
                    "started_on": string|null,
                    "ended_on": string|null,
                    "order_index": number|null,
                    "reference_url": string|null
                  }
                ]
              }
            ],
            "skills": [string],
            "meta": {
              "pages": number,
              "course_catalog_lines": number
            }
          }
        SCHEMA
      end

      def rules_block
        <<~RULES
          - Parse the IMAGES as OCR. Do not hallucinate: if uncertain, leave the field null.
          - Dates MUST be ISO (YYYY-MM-DD). When the day is unknown, use the first day of the month (YYYY-MM-01).
            When both month and day are unknown, use January 01 (YYYY-01-01).
          - If a job end date is "Present" or similar, set "ended_on": null and "current": true. Otherwise "current": false.
          - Normalize phone to digits only (keep country code digits if present).
          - Expand linkedin/github to full URLs when possible.
          - Join responsibility bullets with newline.
          - Keep arrays present even if empty.
          - Output ONLY the JSON object — no prose.

          LANGUAGE extraction:
          - Only populate "languages" when there is explicit proficiency evidence (e.g., "English: B2", "Fluent English").
          - Map common phrases to CEFR (e.g., "Fluent" -> C1; "Intermediate" -> B1; etc.).

          COURSES:
          - Do NOT output any general courses. Always keep "courses_mapped_to_catalog": [] and "courses_to_create": [] empty.

          EXPERIENCES:
          - Only use "experiences" when the document clearly separates initiatives/projects under that job.

          VALIDATION:
          - Ensure all top-level keys exist exactly as in the schema.
          - No duplicate keys. Strict JSON.
        RULES
      end

      def instruction_block
        catalog_text =
          if course_catalog.any?
            "A course catalog was provided but MUST NOT be used. Keep both course arrays empty. (#{course_catalog.size} lines hidden.)"
          else
            "No course catalog provided."
          end

        meta_hint_lines = []
        meta_hint_lines << "Document mode: #{mode}"
        meta_hint_lines << "Pages (detected): #{pages_count}"
        meta_hint_lines << "Course catalog lines (for meta only): #{course_catalog.size}"

        <<~TXT
          #{catalog_text}

          You MUST produce a single JSON object matching this schema exactly:

          #{schema_block}

          Apply these rules strictly:
          #{rules_block}

          Context:
          #{meta_hint_lines.join("\n")}
        TXT
      end

      def data_urls
        images.map do |path|
          "data:image/jpeg;base64,#{Base64.strict_encode64(File.binread(path))}"
        end
      end
    end
  end
end
