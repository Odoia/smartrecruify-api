# app/services/documents/pdf/ai_prompt_builder.rb
# frozen_string_literal: true

require "base64"

module Documents
  module Pdf
    class AiPromptBuilder
      # === SYSTEM: papel e formato de saída ===================================
      SYSTEM = <<~SYS
        You are a strict JSON generator and an expert resume/CV parser.
        You will receive 1..N page IMAGES of a document (PDF converted to JPEG).
        Your only job is to OCR the images carefully and return ONE single JSON object matching EXACTLY the schema and rules below.
        Do not include any explanations, comments, markdown, or code fences — return ONLY raw JSON.
      SYS

      # === SCHEMA de saída (alinhado ao backend) ===============================
      SCHEMA = <<~SCHEMA
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
              "degree_level": string|null,          // e.g., "bachelor", "master", "phd" (ou no idioma do documento se só houver isso)
              "program_name": string|null,
              "started_on": string|null,            // YYYY-MM-DD (use 01 para dia/mês desconhecidos)
              "expected_end_on": string|null,       // YYYY-MM-DD
              "ended_on": string|null,              // YYYY-MM-DD
              "status": "completed"|"in_progress",
              "gpa": string|null,
              "transcript_url": string|null
            }
          ],
          "courses_mapped_to_catalog": [],          // ALWAYS keep as an array; leave EMPTY
          "courses_to_create": [],                  // ALWAYS keep as an array; leave EMPTY
          "languages": [                            // Populate ONLY if there is explicit proficiency evidence
            {
              "language": string,                   // e.g., "English", "Português", "Spanish"
              "proficiency": "A1"|"A2"|"B1"|"B2"|"C1"|"C2"|null
            }
          ],
          "employment": [
            {
              "company_name": string,
              "job_title": string,
              "started_on": string,                 // YYYY-MM-DD
              "ended_on": string|null,              // null if currently employed or "Present"
              "current": boolean,
              "location": string|null,
              "job_description": string|null,       // resumo livre, se existir
              "responsibilities": string|null,      // bullets unidos com "\n"
              "experiences": [
                {
                  "title": string,
                  "description": string|null,
                  "impact": string|null,
                  "skills": [string],
                  "tools": [string],
                  "tags": [string],
                  "metrics": object,                // ex.: {"time_to_productivity_reduction_days": 14}
                  "started_on": string|null,        // YYYY-MM-DD
                  "ended_on": string|null,          // YYYY-MM-DD
                  "order_index": number|null,
                  "reference_url": string|null
                }
              ]
            }
          ],
          "skills": [string],
          "meta": {
            "pages": number,                        // se conhecido
            "course_catalog_lines": number          // passe o valor fornecido
          }
        }
      SCHEMA

      # === REGRAS fortes e de normalização ====================================
      RULES = <<~RULES
        - Parse the IMAGES as OCR. Do not hallucinate: if uncertain, leave the field null.
        - Dates MUST be ISO (YYYY-MM-DD). When the day is unknown, use the first day of the month (YYYY-MM-01).
          When both month and day are unknown, use January 01 (YYYY-01-01).
        - If a job end date is "Present" or similar, set "ended_on": null and "current": true. Otherwise "current": false.
        - Normalize phone to digits only (keep country code digits if present); do not add a plus sign unless explicitly present in the document.
        - Expand linkedin/github into full URLs when possible (e.g., "linkedin.com/in/slug" -> "https://www.linkedin.com/in/slug"; "github.com/user" -> "https://github.com/user").
        - Join responsibility bullets into a single string separated by newline characters.
        - Keep arrays present even if empty.
        - Keep JSON strictly valid: no trailing commas, correct brackets, correct string quoting.
        - Output ONLY the JSON object — no prose or additional text.

        LANGUAGE extraction:
        - Only populate "languages" when there is EXPLICIT evidence of language proficiency or level in the document (e.g., "English: B2", "Fluent English", "Native Portuguese").
        - If there is only generic text like "worked in English-speaking environment" without a stated level, DO NOT add a language item.
        - Map common labels to CEFR when explicit words are used:
            "Native" -> C2
            "Fluent" -> C1 (use C2 only if explicitly stated "near-native" or equivalent)
            "Advanced" -> C1
            "Upper-Intermediate" -> B2
            "Intermediate" -> B1 or B2; if unspecified, use B1
            "Basic" / "Beginner" -> A2
          If a level letter (A1/A2/B1/B2/C1/C2) is explicitly given, use it as-is.
        - If there is a language with NO explicit level but explicit proficiency phrase (e.g., "professional working proficiency"), map reasonably:
            "Professional working proficiency" -> C1
            "Limited working proficiency" -> B1
            "Elementary proficiency" -> A2
          If the phrase is too vague, omit the language entry.

        COURSES:
        - Do NOT output any general courses (even if present on the resume).
        - Always keep "courses_mapped_to_catalog": [] and "courses_to_create": [] as EMPTY arrays.

        EXPERIENCES:
        - Only use "experiences" inside a job when the document clearly separates initiatives/projects under that job.
          Otherwise, leave "experiences": [].

        VALIDATION:
        - Ensure all top-level keys exist exactly as in the schema.
        - Do not duplicate keys.
      RULES

      # === Builder: retorna { messages: [...] } para o client ==================
      #
      # @param course_catalog [Array<String>] ainda aceito, porém não será usado para cursos (mantemos apenas meta)
      # @param image_paths    [Array<String>] caminhos para JPEGs (uma por página)
      # @param mode           [Symbol]        :resume (default) – reservado p/ futuros documentos
      # @param course_catalog_lines [Integer] número de linhas do catálogo incluído (para meta)
      # @param pages_count    [Integer,nil]   número de páginas detectado (para meta)
      #
      # @return [Hash] { messages: [...] } pronto para Ai::Client
      def self.build(course_catalog:, image_paths:, mode: :resume, course_catalog_lines: nil, pages_count: nil, **_opts)
        # Mantemos a seção de catálogo apenas como contexto (não influencia cursos)
        catalog_text =
          if course_catalog.present?
            "A course catalog was provided but MUST NOT be used. You must keep both course arrays empty.\n(#{course_catalog.size} lines hidden for brevity.)"
          else
            "No course catalog provided."
          end

        meta_hint_lines = []
        meta_hint_lines << "Document mode: #{mode}"
        meta_hint_lines << "Pages (if known): #{pages_count}" if pages_count
        meta_hint_lines << "Course catalog lines (for meta only): #{course_catalog_lines || course_catalog.size}"

        instruction_block = <<~TXT
          #{catalog_text}

          You MUST produce a single JSON object matching this schema exactly:

          #{SCHEMA}

          Apply these rules strictly:
          #{RULES}

          Context:
          #{meta_hint_lines.join("\n")}
        TXT

        # Conteúdo multimodal: primeiro “text”, depois N imagens (data URI)
        user_parts = []
        user_parts << { type: "text", text: instruction_block.strip }

        image_paths.each do |path|
          data_uri = "data:image/jpeg;base64,#{Base64.strict_encode64(File.binread(path))}"
          user_parts << {
            type: "image_url",
            image_url: { url: data_uri, detail: "high" }
          }
        end

        {
          messages: [
            { role: "system", content: SYSTEM },
            { role: "user",   content: user_parts }
          ]
        }
      end
    end
  end
end
