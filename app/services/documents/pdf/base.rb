# frozen_string_literal: true

module Documents
  module Pdf
    class Base
      def self.call(file_path:, user:, dry_run: false, course_catalog: [])
        # ==== 0) parâmetros de payload via ENV (fácies de tuning) ====
        pages_limit = Integer(ENV.fetch("PDF_PAGES_LIMIT", 6))
        dpi         = Integer(ENV.fetch("PDF_DPI", 120))
        max_width   = Integer(ENV.fetch("PDF_MAX_WIDTH", 1200))
        quality     = Integer(ENV.fetch("PDF_JPEG_QUALITY", 75))

        # 1) PDF -> JPEG
        to_jpeg = Documents::Pdf::ToJpeg.call(
          file_path: file_path,
          basename:  "page",
          dpi:       dpi,
          max_width: max_width,
          quality:   quality,
          pages_limit: pages_limit
        )
        return fail_ai("pdf_to_jpeg_failed: #{to_jpeg[:message]}") unless to_jpeg[:ok]
        images = to_jpeg[:images]
        return fail_ai("pdf_to_jpeg_failed: no images produced") if images.empty?

        # 2) Prompt
        prompt = Documents::Pdf::AiPromptBuilder.build(
          course_catalog:       course_catalog,
          image_paths:          images,
          mode:                 :resume,
          course_catalog_lines: course_catalog.size
        )

        # 3) Chamada IA com retentativas (timeouts de rede)
        data = with_retries(max_attempts: 3, base_sleep: 1.0) do
          response = Ai::Client.client.chat(
            parameters: {
              model:       Ai::Client.model,
              temperature: 0,
              messages:    prompt[:messages]
            }
          )
          parsed = parse_json_response(response)
          raise "empty_ai_response" if parsed.nil?
          parsed
        end

        # 4) Dry-run
        return { ok: true }.merge(data).merge(meta: { pages: images.size, course_catalog_lines: course_catalog.size }) if dry_run

        # 5) Persistência (plugar seus handlers)
        # Documents::Persist::Employment.call(...)
        # Documents::Persist::Education.call(...)
        # Documents::Persist::Courses.call(...)

        { ok: true }.merge(data).merge(meta: { pages: images.size, course_catalog_lines: course_catalog.size })
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
        fail_ai("network_timeout: #{e.class.name}")
      rescue => e
        fail_ai(e.message)
      end

      def self.with_retries(max_attempts:, base_sleep:)
        attempts = 0
        begin
          attempts += 1
          return yield
        rescue Faraday::TimeoutError, Faraday::ConnectionFailed
          raise if attempts >= max_attempts
          sleep(base_sleep * attempts) # backoff linear simples
          retry
        end
      end

      def self.parse_json_response(response)
        content = response.dig("choices", 0, "message", "content").to_s
        return nil if content.empty?
        JSON.parse(content) rescue nil
      end

      def self.fail_ai(msg)
        { ok: false, error: "import_failed", message: "ai_parse_failed: #{msg}" }
      end
    end
  end
end
