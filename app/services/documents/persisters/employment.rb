# app/services/documents/persisters/employment.rb
# frozen_string_literal: true

module Documents
  module Persisters
    class Employment
      def initialize(user_id:, items:)
        @user_id = user_id
        @items   = Array(items)
      end

      def call
        return ok(0, []) if @items.empty?

        model = ::EmploymentRecord
        cols  = model.column_names
        changed = []

        ActiveRecord::Base.transaction do
          @items.each do |raw|
            h = stringify_keys(raw)

            # chave natural apenas com colunas existentes
            key = { user_id: @user_id }
            key[:company_name] = h["company_name"] if cols.include?("company_name")
            key[:job_title]    = h["job_title"]    if cols.include?("job_title")
            key[:started_on]   = h["started_on"]   if cols.include?("started_on") && h["started_on"].present?

            rec = model.find_or_initialize_by(key)

            allowed_input = %w[
              company_name job_title started_on ended_on current
              location job_description responsibilities
            ]
            allowed = allowed_input & cols
            rec.assign_attributes(h.slice(*allowed))

            # só força ended_on=nil se existirem as colunas
            if cols.include?("current") && cols.include?("ended_on")
              if truthy(rec.current)
                rec.ended_on = nil
              end
            end

            action = rec.new_record? ? :created : :updated
            rec.save!
            changed << { id: rec.id, action: action }
          end
        end

        ok(changed.size, changed)
      rescue => e
        error(e)
      end

      private

      def stringify_keys(obj)
        obj.to_h.transform_keys(&:to_s)
      end

      def truthy(v)
        case v
        when true, "true", 1, "1", "yes", "on" then true
        else false
        end
      end

      def ok(count, items); { ok: true, count:, items: }; end
      def error(e);         { ok: false, error: e.message }; end
    end
  end
end
