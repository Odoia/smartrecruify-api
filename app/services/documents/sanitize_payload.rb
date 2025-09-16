# frozen_string_literal: true

module Documents
  class SanitizePayload
    class << self
      def call(payload)
        p = deep_dup(payload || {})

        p["basic"]                     = sanitize_basic(p["basic"])
        p["education_records"]         = sanitize_educations(p["education_records"])
        p["employment"]                = sanitize_employment(p["employment"])
        p["skills"]                    = sanitize_skills(p["skills"])
        p["courses_mapped_to_catalog"] = Array(p["courses_mapped_to_catalog"])
        p["courses_to_create"]         = Array(p["courses_to_create"])
        p["languages"]                 = Array(p["languages"])
        p["meta"]                      = sanitize_meta(p["meta"]) # ← garante único

        # Remove qualquer chave que não esteja no contrato
        p.slice(
          "basic",
          "education_records",
          "employment",
          "skills",
          "courses_mapped_to_catalog",
          "courses_to_create",
          "languages",
          "meta"
        )
      end

      private

      def deep_dup(obj)
        Marshal.load(Marshal.dump(obj))
      end

      # ---------------- BASIC ----------------
      def sanitize_basic(basic)
        b = (basic || {}).slice(
          "full_name", "headline", "address", "phone", "email", "linkedin_url", "github_url"
        )
        b["phone"]        = digits_only(b["phone"])
        b["linkedin_url"] = normalize_link(b["linkedin_url"], "linkedin.com")
        b["github_url"]   = normalize_link(b["github_url"],   "github.com")
        b
      end

      def digits_only(s)
        s.to_s.gsub(/\D+/, "").presence
      end

      def normalize_link(url, domain)
        u = url.to_s.strip
        return nil if u.empty?

        # tira schema/www
        u = u.sub(%r{\Ahttps?://}i, "")
        u = u.sub(%r{\Awww\.}i, "")

        # garante domínio correto
        unless u.start_with?(domain)
            # pega o sufixo após a primeira barra encontrada no original
            suffix = u.split("/", 2).last
            suffix = suffix ? "/#{suffix}" : ""
            u = "#{domain}#{suffix}"
        end

        "https://#{u}"
      end

      # --------------- EDUCATION ---------------
      def sanitize_educations(list)
        Array(list).map do |e|
          (e || {}).slice(
            "institution_name", "degree_level", "program_name",
            "started_on", "expected_end_on", "ended_on",
            "status", "gpa", "transcript_url"
          )
        end
      end

      # --------------- EMPLOYMENT ---------------
      def sanitize_employment(list)
        jobs = Array(list).map { |j| sanitize_job(j) }

        # Apenas 1 `current: true` ⇒ escolhe o mais recente por data (started_on, senão ended_on)
        current_idxs = jobs.each_index.select { |i| jobs[i]["current"] }
        if current_idxs.size > 1
          winner_idx = current_idxs.max_by { |i| job_recency_key(jobs[i]) }
          current_idxs.each do |i|
            jobs[i]["current"] = (i == winner_idx)
            jobs[i]["ended_on"] = nil if jobs[i]["current"]
          end
        end

        jobs
      end

      def sanitize_job(j)
        h = (j || {}).slice(
          "company_name", "job_title", "started_on", "ended_on", "current",
          "location", "job_description", "responsibilities", "experiences"
        )

        # coerência `current`/datas
        h["current"] = !!h["current"]
        if h["current"]
          h["ended_on"] = nil
        end

        # parse/normalize datas para ISO (se já vierem ISO, mantém)
        h["started_on"] = iso_or_nil(h["started_on"])
        h["ended_on"]   = iso_or_nil(h["ended_on"])

        # mantém array mesmo vazio
        h["experiences"] = Array(h["experiences"])

        h
      end

      def job_recency_key(job)
        # usa star[48;79;156;1343;1248tted_on; fallback para ended_on; senão mínimo
        parse_date(job["started_on"]) ||
          parse_date(job["ended_on"]) ||
          Date.new(0)
      end

      def iso_or_nil(s)
        d = parse_date(s)
        d&.strftime("%Y-%m-%d")
      end

      def parse_date(s)
        return nil if s.blank?
        Date.iso8601(s)
      rescue ArgumentError
        nil
      end

      # ---------------- SKILLS ----------------
      def sanitize_skills(list)
        tokens = Array(list).flat_map { |s| split_tokens(s) }
        tokens = tokens.map { |t| normalize_skill_token(t) }
        tokens.reject(&:blank?).uniq
      end

      def split_tokens(s)
        return [] if s.blank?
        s.to_s.split(%r{[,/|]| \+ |\+}).map { |t| t.strip }.reject(&:empty?)
      end

      def normalize_skill_token(s)
        t = s.to_s.strip
        return "" if t.empty?

        key = t.downcase

        # Correções genéricas (sem depender de PDF específico)
        generic = {
          "api rest"   => "REST API",
          "rest api"   => "REST API",
          "node"       => "Node.js",
          "typescript" => "TypeScript",
          "javascript" => "JavaScript",
          "jquery"     => "jQuery",
          "pl/sql"     => "PL/SQL",
          "docker swarm" => "Docker Swarm"
        }
        return generic[key] if generic[key]

        # Acrônimos comuns
        return t.upcase if %w[php sql api css html lua].include?(key)

        # Titleize leve
        t.split.map(&:capitalize).join(" ")
      end

      # ---------------- META ----------------
      def sanitize_meta(meta)
        m = (meta || {}).slice("pages", "course_catalog_lines")
        {
          "pages" => m["pages"],
          "course_catalog_lines" => m["course_catalog_lines"]
        }
      end
    end
  end
end
