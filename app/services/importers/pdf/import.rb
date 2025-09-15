# frozen_string_literal: true
module Importers
  module Pdf
    class Import
      # Orchestrates the full flow: validate -> extract_text -> detect_kind -> run specialized steps -> persist/dry-run
      def self.call(file:, user:, dry_run: false, source: :auto)
        raise ArgumentError, "file required" if file.blank?

        v = Validate.call(file: file)
        return error(:invalid_pdf, v.reasons) unless v.ok

        t = ExtractText.call(file: file)
        return error(:empty_text) if t.raw_text.to_s.strip.empty?

        kind = (source == :auto ? DetectKind.call(text: t.raw_text) : source)
        # kind will be a symbol, e.g., :linkedin, :cv, or :unknown
        return error(:unsupported_pdf) if kind == :unknown

        # Resolve modules for the detected kind (falls back to generic handlers if a specialization is missing)
        adapters = Adapters.for(kind)

        ai = adapters.extract_ai.call(text: t.raw_text)
        return error(:ai_no_data) if ai.extracted.blank?

        norm = adapters.normalize.call(extracted: ai.extracted)
        return error(:normalized_empty) if norm.data.blank?

        if dry_run
          return {
            ok: true,
            dry_run: true,
            meta: { user_id: user&.id, kind: kind, confidence: ai.confidence, missing_fields: ai.missing_fields },
            extracted: norm.data
          }
        end

        per = adapters.persist.call(user: user, data: norm.data)
        {
          ok: true,
          dry_run: false,
          meta: { user_id: user&.id, kind: kind },
          summary: per.summary
        }
      rescue => e
        error(:import_failed, e.message)
      end

      def self.error(code, details = nil)
        { ok: false, error: code.to_s, details: details }
      end

      # Simple adapter registry resolving the specialized classes by kind
      module Adapters
        def self.for(kind)
          case kind
          when :linkedin
            ExtractorSet.new(
              extract_ai: Importers::Linkedin::Pdf::ExtractAi,
              normalize:  Importers::Linkedin::Pdf::Normalize,
              persist:    Importers::Linkedin::Pdf::Persist
            )
          when :cv
            ExtractorSet.new(
              extract_ai: Importers::Cv::Pdf::ExtractAi,
              normalize:  Importers::Cv::Pdf::Normalize,
              persist:    Importers::Cv::Pdf::Persist
            )
          else
            # default fallback
            ExtractorSet.new(
              extract_ai: Importers::Pdf::ExtractAi,
              normalize:  Importers::Pdf::Normalize,
              persist:    Importers::Pdf::Persist
            )
          end
        end

        ExtractorSet = Struct.new(:extract_ai, :normalize, :persist, keyword_init: true)
      end
    end
  end
end
