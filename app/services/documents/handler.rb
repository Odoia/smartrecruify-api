# frozen_string_literal: true

require "tempfile"
require "fileutils"

module Documents
  class Handler
    # Roteia por tipo de documento. Por enquanto só PDF.
    # Sempre retorna { ok: true/false, payload: Hash } quando ok=true
    def self.call(file:, user:, dry_run: false, course_catalog: [])
      content_type = file.content_type.to_s
      extname      = File.extname(file.original_filename.to_s).downcase

      unless pdf_mime?(content_type, extname)
        return { ok: false, error: "unsupported_document_type", message: "Only PDF is supported for now." }
      end

      tmp_pdf = save_upload(file)

      begin
        raw_result = Documents::Pdf::Base.call(
          file_path:      tmp_pdf,
          user:           user,
          dry_run:        dry_run,
          course_catalog: course_catalog
        )

        # -------------------------------
        # Normaliza formatos de retorno:
        # 1) { ok:, payload: {...} }
        # 2) { ok:, basic:..., employment:..., meta:... } (chapado)
        # -------------------------------
        ok_flag = raw_result.is_a?(Hash) ? (raw_result[:ok].nil? ? raw_result["ok"] : raw_result[:ok]) : false
        unless ok_flag
          # erro: apenas repassa
          return raw_result.is_a?(Hash) ? raw_result : { ok: false, error: "import_failed", message: "Unknown error" }
        end

        payload =
          if raw_result.is_a?(Hash) && raw_result[:payload].is_a?(Hash)
            raw_result[:payload]
          elsif raw_result.is_a?(Hash) && raw_result["payload"].is_a?(Hash)
            raw_result["payload"]
          elsif raw_result.is_a?(Hash)
            # remove chaves de controle comuns e considera o resto como payload
            raw_result.dup.tap { |h| h.delete(:ok); h.delete("ok"); h.delete(:error); h.delete("error"); h.delete(:message); h.delete("message") }
          else
            {}
          end

        sanitized = Documents::SanitizePayload.call(payload)

        { ok: true, payload: sanitized }
      ensure
        FileUtils.rm_f(tmp_pdf) if tmp_pdf && File.exist?(tmp_pdf)
      end
    rescue => e
      { ok: false, error: "import_failed", message: e.message }
    end

    def self.pdf_mime?(content_type, extname)
      return true if content_type == "application/pdf"
      return true if extname == ".pdf"
      false
    end

    def self.save_upload(file)
      dir = Dir.mktmpdir("doc_upload")
      path = File.join(dir, (file.original_filename.presence || "upload.pdf"))
      File.open(path, "wb") { |f| f.write(file.read) }
      path
    end
  end
end
