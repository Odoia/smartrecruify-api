# frozen_string_literal: true
# You can switch this to PDF::Reader, PDF::Inspector, or HexaPDF; keeping it abstract.
require "pdf/reader"

module Importers
  module Pdf
    class ExtractText
      Result = Struct.new(:raw_text, :pages_text, keyword_init: true)

      def self.call(file:, safe: false)
        io = file.respond_to?(:path) ? File.open(file.path, "rb") : file.tempfile || file
        reader = ::PDF::Reader.new(io)
        pages = reader.pages.map { |p| sanitize(p.text) }
        Result.new(raw_text: pages.join("\n"), pages_text: pages)
      rescue => e
        raise e unless safe
        Result.new(raw_text: "", pages_text: [])
      ensure
        io.close if io.is_a?(File)
      end

      # Basic cleanup that helps prompting (trim odd spaces, normalize whitespace)
      def self.sanitize(text)
        s = text.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
        s.gsub(/\u00A0/, " ").gsub(/[ \t]+/, " ").gsub(/\s+\n/, "\n").strip
      end
    end
  end
end
