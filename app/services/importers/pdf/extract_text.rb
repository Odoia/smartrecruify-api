# frozen_string_literal: true

require "pdf/reader"

module Importers
  module Pdf
    class ExtractText
      def self.call(file)
        io = file.respond_to?(:path) ? File.open(file.path, "rb") : file.tempfile
        reader = ::PDF::Reader.new(io)
        text = reader.pages.map(&:text).join("\n")
        { ok: true, text: text }
      rescue => e
        { ok: false, error: "unreadable_pdf", message: e.message }
      ensure
        io.close if io && !io.closed? rescue nil
      end
    end
  end
end
