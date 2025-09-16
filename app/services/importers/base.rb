# app/services/importers/base.rb
# frozen_string_literal: true

require "pdf/reader"
require "json"

module Importers
  class Base
    SCHEMA = {
      basic: {
        full_name: nil, headline: nil, email: nil, phone: nil,
        linkedin_url: nil, github_url: nil
      },
      education_records: [
        {
          degree_level: nil, institution_name: nil, program_name: nil,
          started_on: nil, expected_end_on: nil, ended_on: nil,
          status: nil, gpa: nil, transcript_url: nil
        }
      ],
      courses_mapped_to_catalog: [
        { course_id: nil, status: nil, started_on: nil, expected_end_on: nil, completed_on: nil, progress_percent: nil }
      ],
      courses_to_create: [
        { name: nil, provider: nil, category: nil, hours: nil, description: nil, status: nil,
          started_on: nil, expected_end_on: nil, completed_on: nil, progress_percent: nil }
      ],
      employment: [
        {
          company: nil, job_title: nil, started_on: nil, ended_on: nil, current: nil,
          location: nil, job_description: nil, responsibilities: nil,
          experiences: [
            { title: nil, description: nil, impact: nil, skills: [], tools: [], tags: [], metrics: {},
              started_on: nil, ended_on: nil, order_index: nil, reference_url: nil }
          ]
        }
      ],
      skills: []
    }.freeze

    def self.call(file:, user:, dry_run: false, source: :linkedin)
      new(file:, user:, dry_run:, source:).call
    end

    def initialize(file:, user:, dry_run:, source:)
      @file    = file
      @user    = user
      @dry_run = !!dry_run
      @source  = (source || :linkedin).to_sym
    end

    def call
      return error!("file_missing") if @file.blank?

      # 1) PDF -> texto
      text_rs = extract_text(@file)
      return error!(text_rs[:error] || "unreadable_pdf", message: text_rs[:message]) unless text_rs[:ok]
      text = text_rs[:text].to_s
      chars_count = text.length

      # 2) Snapshot do catálogo de cursos
      catalog_lines  = load_course_catalog_lines(limit: ENV.fetch("COURSE_CATALOG_LIMIT", 30).to_i)
      catalog_prompt = catalog_lines.join("\n")

      # 3) IA (monta mensagens e chama)
      ai_data = extract_with_ai!(text:, course_catalog_prompt: catalog_prompt)

      # 4) Dry-run: retorna sem persistir
      if @dry_run
        return ok!(ai_data.merge(meta: { course_catalog_lines: catalog_lines.size, chars_count: chars_count }))
      end

      # 5) Persistência (idempotente, de-dup nos handlers)
      education_result = ::Importers::Handlers::EducationHandler.call(
        user: @user,
        education_data: ai_data["education_records"],
        courses_mapped_to_catalog: ai_data["courses_mapped_to_catalog"],
        courses_to_create: ai_data["courses_to_create"],
        dry_run: false
      )

      employment_result = ::Importers::Handlers::EmploymentHandler.call(
        user: @user,
        employment_data: ai_data["employment"],
        dry_run: false
      )

      ok!(
        ai_data.merge(
          persisted: {
            education_records_saved: Array(education_result&.records).size,
            employment_saved:        Array(employment_result&.records).size
          },
          meta: { course_catalog_lines: catalog_lines.size, chars_count: chars_count }
        )
      )
    rescue => e
      Rails.logger.error("[IMPORTERS::BASE] #{e.class}: #{e.message}\n#{Array(e.backtrace).first(5).join("\n")}")
      error!("import_failed", message: e.message)
    end

    private

    # ============ PDF ============
    def extract_text(file)
      io = file.respond_to?(:path) ? File.open(file.path, "rb") : file.tempfile
      reader = ::PDF::Reader.new(io)
      text = reader.pages.map(&:text).join("\n")
      { ok: true, text: text }
    rescue => e
      { ok: false, error: "unreadable_pdf", message: e.message }
    ensure
      begin io.close if io && !io.closed? rescue nil end
    end

    # ============ IA ============
    def extract_with_ai!(text:, course_catalog_prompt:)
      useful_text = text.to_s[0, 10_000] # truncagem defensiva

      system_msg = <<~SYS
        Você é um extrator de dados de currículos/CVs.
        Regras:
        - Responda SOMENTE com um único objeto JSON válido.
        - **Não inclua** markdown, backticks, comentários, nem texto fora do JSON.
        - Use null quando não tiver certeza. Arrays podem ser vazios.
        - Datas: ISO YYYY-MM-DD (se só houver ano/mês, use dia 01).
      SYS

      user_prompt = <<~TXT
        Você receberá:
        (1) TEXTO plano do currículo (na próxima mensagem),
        (2) CATÁLOGO DE CURSOS no formato: "course_id | provider | name | category | hours".

        TAREFA:
        - Siga o SCHEMA (shape) abaixo. Não invente dados; deixe null/arrays vazios.
        - "Present/Atual" => ended_on = null e current = true.
        - Cursos:
          a) Se corresponder a um do catálogo (provider + nome parecido), preencha em courses_mapped_to_catalog com o course_id.
          b) Caso contrário, proponha em courses_to_create com {name, provider, category, hours, description} + status/datas.
        - Não duplique o mesmo curso.

        CATÁLOGO DE CURSOS:
        #{course_catalog_prompt}

        SCHEMA/shape esperado:
        #{pretty_shape_for_prompt(SCHEMA)}

        IMPORTANTE: Responda com JSON único e válido, sem trailing commas.
      TXT

      messages = [
        { role: "system", content: system_msg },
        { role: "user",   content: user_prompt },
        { role: "user",   content: useful_text }
      ]

      raw = Ai::Client.client.chat(
        parameters: {
          model: Ai::Client.model,
          messages: messages,
          temperature: 0,
          max_tokens: 400,
          response_format: { type: "json_object" }
        }
      )

      content = raw.dig("choices", 0, "message", "content").to_s
      begin
        data = parse_json_strict(content)
      rescue => e
        # Fallback 1: pedir para a IA reparar o JSON e tentar de novo
        repaired_by_ai = ai_fix_json!(bad_text: content, schema_shape: SCHEMA)
        data = parse_json_strict(repaired_by_ai)
      end

      normalize!(data)
    rescue => e
      raise StandardError, "ai_parse_failed: #{e.message}"
    end

    # Pede para a IA reformatar/validar JSON malformado
    def ai_fix_json!(bad_text:, schema_shape:)
      sys = "Você reescreve a entrada como um ÚNICO objeto JSON VÁLIDO. Sem markdown, sem comentários."
      prompt = <<~P
        Conserte o JSON abaixo para ficar 100% válido e aderente ao shape fornecido.
        Se houver campos extras irrelevantes, ignore-os. Preencha faltas com null ou arrays vazios.
        SHAPE:
        #{pretty_shape_for_prompt(schema_shape)}

        TEXTO A CORRIGIR:
        #{bad_text}
      P

      resp = Ai::Client.client.chat(
        parameters: {
          model: Ai::Client.model,
          messages: [
            { role: "system", content: sys },
            { role: "user",   content: prompt }
          ],
          temperature: 0,
          max_tokens: 1200,
          response_format: { type: "json_object" }
        }
      )
      resp.dig("choices", 0, "message", "content").to_s
    end

    # ============ Catálogo ============
    def load_course_catalog_lines(limit:)
      Course
        .select(:id, :name, :provider, :category, :hours)
        .order(Arel.sql("LOWER(provider), LOWER(name)"))
        .limit(limit)
        .map { |c| [c.id, scrub(c.provider), scrub(c.name), scrub(c.category), c.hours.to_i].join(" | ") }
    end

    # ============ Utilidades de normalização/parse ============
    def parse_json_strict(text)
      cleaned = strip_code_fences(text.to_s)
      return {} if cleaned.strip.empty?

      begin
        return JSON.parse(cleaned)
      rescue JSON::ParserError
        # tenta extrair o primeiro objeto JSON bem-delimitado
        object_only = cleaned[/\{.*\}/m]
        raise "AI JSON parse error (no object found)" unless object_only

        begin
          return JSON.parse(object_only)
        rescue JSON::ParserError
          # reparo defensivo
          repaired = repair_json(object_only)
          return JSON.parse(repaired)
        end
      end
    end

    def strip_code_fences(s)
      x = s.dup
      # remove cercas ```json ... ``` ou ``` ... ```
      x.gsub!(/```json\s*([\s\S]*?)```/i, '\1')
      x.gsub!(/```\s*([\s\S]*?)```/i, '\1')
      # remove linhas de markdown/bullets iniciais antes do JSON
      x.sub!(/\A[\s\S]*?(\{)/m, '{') # corta tudo antes do primeiro '{'
      # normaliza aspas “curly” e simples
      x.tr!("“”‘’", %q{""''})
      x
    end

    def repair_json(s)
      x = s.dup

      # remove comentários //... e /* ... */ (por segurança)
      x.gsub!(%r{//[^\n]*}, "")
      x.gsub!(%r{/\*.*?\*/}m, "")

      # normaliza aspas curvas e substitui aspas simples por duplas quando formam strings JSON
      x.tr!("“”‘’", %q{""''})
      # tentativa leve de trocar 'texto' por "texto" quando está claro que é string JSON
      x.gsub!(/'([^'\\]*?)'/, '"\1"')

      # remove trailing commas antes de '}' ou ']'
      x.gsub!(/,\s*([}\]])/, '\1')

      # corrige ", ]" -> "]" e ", }" -> "}"
      x.gsub!(/,\s*\]/, ']')
      x.gsub!(/,\s*\}/, '}')

      # remove vírgulas duplicadas ",," ocasionais
      x.gsub!(/,,+/, ',')

      # remove caracteres inválidos
      x.encode!("UTF-8", invalid: :replace, undef: :replace, replace: "")

      x
    end

    def normalize!(h)
      h = deep_stringify_keys(h)
      if h["basic"].is_a?(Hash)
        h["basic"]["email"] = h.dig("basic", "email").to_s.strip.downcase.presence
        h["basic"]["phone"] = h.dig("basic", "phone").to_s.strip.presence
      end
      %w[employment education_records courses_mapped_to_catalog courses_to_create].each do |k|
        Array(h[k]).each { |row| normalize_dates!(row) }
      end
      h["skills"] = Array(h["skills"]).map { |x| x.to_s.strip }.reject(&:empty?).uniq
      h
    end

    def normalize_dates!(row)
      %w[started_on ended_on expected_end_on completed_on].each do |f|
        row[f] = iso(row[f]) if row.key?(f)
      end
      if row.key?("current")
        row["current"] = (row["ended_on"].nil? || row["current"] == true)
      end
      if row.key?("progress_percent")
        row["progress_percent"] = row["progress_percent"].to_i
      end
      if row.key?("experiences")
        Array(row["experiences"]).each { |x| normalize_dates!(x) }
      end
    end

    def iso(val)
      s = val.to_s.strip
      return nil if s.empty? || s == "null"
      y, m, d = s.split("-").map(&:to_i)
      y && y > 0 ? format("%04d-%02d-%02d", y, (m > 0 ? m : 1), (d > 0 ? d : 1)) : nil
    rescue
      nil
    end

    def deep_stringify_keys(obj)
      case obj
      when Hash  then obj.each_with_object({}) { |(k, v), h| h[k.to_s] = deep_stringify_keys(v) }
      when Array then obj.map { |e| deep_stringify_keys(e) }
      else obj
      end
    end

    def pretty_shape_for_prompt(obj, indent = 0)
      pad = "  " * indent
      case obj
      when Hash
        inner = obj.map { |k, v| "#{pad}  \"#{k}\": #{pretty_shape_for_prompt(v, indent + 1)}" }.join(",\n")
        "{\n#{inner}\n#{pad}}"
      when Array
        obj.empty? ? "[]" : "[ #{pretty_shape_for_prompt(obj.first, indent)} ]"
      else
        obj.inspect
      end
    end

    def scrub(s) = s.to_s.strip.gsub("|", " ")
    def ok!(payload = {}) = { ok: true }.merge(payload)
    def error!(code, message: nil) = { ok: false, error: code, message: message }.compact
  end
end
