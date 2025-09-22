# frozen_string_literal: true

module Documents
  module Persisters
    # Recebe o payload completo do PDF e despacha
    # para os persisters específicos (Education, Employment, etc).
    class Handler
      DISPATCH_MAP = {
        education: Documents::Persisters::Education
        # employment: Documents::Persisters::Employment,
        # skills:     Documents::Persisters::Skills,
      }.freeze

      KEY_ALIASES = {
        "education_records" => :education,
        :education_records  => :education
      }.freeze

      def self.call(user_id:, payload:)
        new(user_id:, payload:).call
      end

      def initialize(user_id:, payload:)
        @user_id = user_id
        @payload = payload || {}
        @results = {}
      end

      def call
        inner = (@payload[:payload] || @payload["payload"] || {})
        return ok if inner.blank?

        extract_sections(inner).each do |section_key, items|
          persister = DISPATCH_MAP[section_key]
          next unless persister

          result = safe_call(persister, items)
          @results[section_key] = result
        end

        ok
      end

      private

      def extract_sections(inner)
        sections = {}
        KEY_ALIASES.each do |raw_key, normalized|
          value = inner[raw_key] || inner[raw_key.to_s] || inner[raw_key.to_sym]
          sections[normalized] = Array(value) if value.present?
        end
        sections
      end

      def safe_call(klass, items)
        klass.call(user_id: @user_id, items:)
      rescue => e
        { result: false, error: e.message }
      end

      def ok
        { result: true, dispatched: @results }
      end
    end
  end
end
