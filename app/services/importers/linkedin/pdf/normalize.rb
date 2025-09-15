# frozen_string_literal: true
# LinkedIn-specific normalization (date parsing like "Apr 2023 – Present", etc.)
module Importers
  module Linkedin
    module Pdf
      class Normalize < ::Importers::Pdf::Normalize
        class << self
          # Override only what you need. Example: robust natural date parsing from LinkedIn ranges.
          def normalize_employment(h)
            out = super
            # Try to parse "Apr 2023 - Present" if no structured date came from the extractor
            if out[:started_on].nil? && h[:date_range].present?
              s, e = split_range(h[:date_range])
              out[:started_on] = parse_linkedin_date(s)
              out[:ended_on]   = parse_linkedin_date(e)
              out[:current]    = (e.to_s.downcase == "present")
            end
            out
          end

          def split_range(s)
            s.to_s.split(/-|–|—/).map(&:strip).then { |a| [a[0], a[1]] }
          end

          def parse_linkedin_date(s)
            return nil if s.blank?
            # Accept "Apr 2023", "March 2021", "2019"
            str = s.to_s
            if str =~ /^\d{4}$/ then str
            elsif str =~ /^[A-Za-z]{3,9}\s+\d{4}$/ then str # keep as-is; your DB layer may accept strings or map later
            else nil end
          end
        end
      end
    end
  end
end
