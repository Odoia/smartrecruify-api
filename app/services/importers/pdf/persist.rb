# frozen_string_literal: true
module Importers
  module Pdf
    class Persist
      Result = Struct.new(:summary, keyword_init: true)

      # Default persistence if you want a generic target; most cases will override by source.
      def self.call(user:, data:)
        # No-op default so the generic pipeline still runs in dry-run.
        Result.new(summary: { created: {}, updated: {} })
      end
    end
  end
end
