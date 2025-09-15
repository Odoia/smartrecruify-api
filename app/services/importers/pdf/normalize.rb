# frozen_string_literal: true
module Importers
  module Pdf
    class Normalize
      Result = Struct.new(:data, keyword_init: true)

      # Conform raw fields to your domain structure (dates, enums, trims, dedupe)
      def self.call(extracted:)
        data = {
          basic: normalize_basic(extracted[:basic] || {}),
          employment: (extracted[:employment] || []).map { |e| normalize_employment(e) },
          education: (extracted[:education] || []).map { |e| normalize_education(e) },
          skills: (extracted[:skills] || []).map { |s| normalize_skill(s) }
        }
        Result.new(data: data)
      end

      def self.normalize_basic(h)
        {
          full_name: blank_to_nil(h[:full_name]),
          headline:  blank_to_nil(h[:headline]),
          email:     blank_to_nil(h[:email]),
          phone:     blank_to_nil(h[:phone]),
          linkedin_url: blank_to_nil(h[:linkedin_url]),
          github_url:   blank_to_nil(h[:github_url])
        }
      end

      def self.normalize_employment(h)
        {
          company_name: blank_to_nil(h[:company_name]),
          job_title:    blank_to_nil(h[:job_title]),
          started_on:   normalize_date(h[:started_on]),
          ended_on:     normalize_date(h[:ended_on]),
          current:      !!h[:current],
          location:     blank_to_nil(h[:location]),
          description:  truncate((h[:description] || "").strip, 2000)
        }
      end

      def self.normalize_education(h)
        {
          institution_name: blank_to_nil(h[:institution_name]),
          program_name:     blank_to_nil(h[:program_name]),
          degree_level:     blank_to_nil(h[:degree_level]),
          started_on:       normalize_date(h[:started_on]),
          ended_on:         normalize_date(h[:ended_on]),
          status:           normalize_status(h[:status])
        }
      end

      def self.normalize_skill(h)
        { name: (h.is_a?(Hash) ? h[:name] : h).to_s.strip.presence }
      end

      def self.normalize_status(s)
        return nil if s.blank?
        v = s.to_s.downcase
        %w[in_progress completed dropped paused].include?(v) ? v : nil
      end

      def self.normalize_date(s)
        return nil if s.blank?
        # accept YYYY or YYYY-MM or YYYY-MM-DD, coerce to YYYY-MM-DD when possible
        str = s.to_s.strip
        if str =~ /^\d{4}-\d{2}-\d{2}$/ || str =~ /^\d{4}-\d{2}$/ || str =~ /^\d{4}$/
          str
        else
          nil
        end
      end

      def self.truncate(s, len)
        s.to_s.length > len ? s.to_s[0...len] : s.to_s
      end

      def self.blank_to_nil(v)
        v.to_s.strip.presence
      end
    end
  end
end
