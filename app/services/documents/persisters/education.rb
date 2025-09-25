# frozen_string_literal: true

module Documents
  module Persisters
    # app/services/documents/persisters/education.rb
    class Education
      def initialize(user_id:, items:)
        @user_id = user_id
        @items   = Array(items)
      end

      # Upsert de EducationRecord via EducationProfile
      # Chave natural: [institution_name, program_name, started_on, completed_on]
      def call
        return ok(0, []) if @items.empty?

        model   = ::EducationRecord
        cols    = model.column_names
        profile = ::EducationProfile.find_or_create_by!(user_id: @user_id)

        changed = []
        errors  = []

        @items.each_with_index do |raw, idx|
          src = raw.to_h.transform_keys(&:to_s)

          completed_on = src["completed_on"].presence || src["ended_on"].presence
          started_on   = src["started_on"].presence

          # chave natural
          key = { education_profile_id: profile.id }
          key[:institution_name] = src["institution_name"] if cols.include?("institution_name")
          key[:program_name]     = src["program_name"]     if cols.include?("program_name")
          key[:started_on]       = started_on              if cols.include?("started_on")   && started_on.present?
          key[:completed_on]     = completed_on            if cols.include?("completed_on") && completed_on.present?

          rec = model.find_or_initialize_by(key)

          # attrs do payload → colunas
          attrs = {}
          attrs["institution_name"] = src["institution_name"] if cols.include?("institution_name")
          attrs["program_name"]     = src["program_name"]     if cols.include?("program_name")
          attrs["started_on"]       = started_on              if cols.include?("started_on")
          attrs["expected_end_on"]  = src["expected_end_on"]  if cols.include?("expected_end_on")
          attrs["completed_on"]     = completed_on            if cols.include?("completed_on")
          attrs["gpa"]              = src["gpa"]              if cols.include?("gpa")
          attrs["transcript_url"]   = src["transcript_url"]   if cols.include?("transcript_url")

          # enums (Rails aceitará string do key do enum)
          if cols.include?("degree_level")
            attrs["degree_level"] = coerce_degree_level(model, src["degree_level"])
          end

          if cols.include?("status")
            attrs["status"] = coerce_status(model, src["status"])
          end

          # regra do modelo: completed_on ⇒ status == "completed"
          if attrs["completed_on"].present? && cols.include?("status")
            attrs["status"] = "completed"
          end

          begin
            rec.assign_attributes(attrs)
            action = rec.new_record? ? :created : :updated
            rec.save!
            changed << { id: rec.id, action: action }
          rescue ActiveRecord::RecordInvalid => e
            errors << { index: idx, key:, errors: rec.errors.full_messages }
          rescue => e
            errors << { index: idx, key:, errors: [e.message] }
          end
        end

        if errors.any?
          { ok: false, count: changed.size, items: changed, errors: errors }
        else
          ok(changed.size, changed)
        end
      rescue => e
        error(e)
      end

      private

      # mapeia strings soltas dos status para keys do enum
      def coerce_status(model, value)
        return nil if value.nil?
        return value if !model.respond_to?(:statuses)

        v = value.to_s.strip.downcase
        return v if model.statuses.key?(v)

        aliases = {
          "in progress" => "in_progress",
          "ongoing"     => "in_progress",
          "enrolado"    => "enrolled",
          "concluido"   => "completed",
          "concluído"   => "completed",
          "pausado"     => "paused",
          "trancado"    => "paused",
          "desistiu"    => "dropped"
        }
        aliases[v] || v
      end

      # normaliza degree_level para enum (pt/en)
      def coerce_degree_level(model, value)
        return nil if value.nil?
        return value if !model.respond_to?(:degree_levels)

        v = value.to_s.strip.downcase
        norm = case v
        when "fundamental", "primario", "primário"      then "primary"
        when "secundario", "secundário"                 then "secondary"
        when "ensino medio", "ensino médio", "colegial" then "high_school"
        when "tecnico", "técnico", "vocação", "vocational" then "vocational"
        when "tecnologo", "tecnólogo", "associate"      then "associate"
        when "bachelor", "bacharelado", "bacharalado"   then "bachelor"
        when "pos", "pós", "pos-graduacao", "pós-graduação", "postgraduate" then "postgraduate"
        when "mestre", "mestrado", "master"             then "master"
        when "doutor", "doutorado", "phd", "doctorate"  then "doctorate"
        else v
        end

        return norm if model.degree_levels.key?(norm)
        v
      end

      def ok(count, items); { ok: true, count:, items: }; end
      def error(e);         { ok: false, error: e.message }; end
    end
  end
end
