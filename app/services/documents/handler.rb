# frozen_string_literal: true

require "tempfile"
require "fileutils"

module Documents
  class Handler
    def call(file:, user:, course_catalog: [])
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

        if raw_result.is_a?(Hash) && raw_result[:ok] && raw_result[:payload].is_a?(Hash)
          if defined?(Documents::SanitizePayload)
            raw_result[:payload] = Documents::SanitizePayload.call(raw_result[:payload])
          end
        end

        raw_result
      ensure
        FileUtils.rm_f(tmp_pdf) if tmp_pdf && File.exist?(tmp_pdf)
      end
    rescue => e
      { ok: false, error: "import_failed", message: e.message }
    end

    private

    def pdf_mime?(content_type, extname)
      return true if content_type == "application/pdf"
      return true if extname == ".pdf"
      false
    end

    def save_upload(file)
      dir  = Dir.mktmpdir("doc_upload")
      name = file.original_filename.presence || "upload.pdf"
      path = File.join(dir, name)
      File.open(path, "wb") { |f| f.write(file.read) }
      path
    end
  end
end
