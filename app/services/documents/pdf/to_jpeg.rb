# frozen_string_literal: true
require "mini_magick"
require "securerandom"
require "fileutils"

module Documents
  module Pdf
    class ToJpeg
      def self.call(file_path:, basename: "page", dpi: 150, max_width: 1600, quality: 85, pages_limit: 6)
        new(file_path:, basename:, dpi:, max_width:, quality:, pages_limit:).call
      end

      def initialize(file_path:, basename:, dpi:, max_width:, quality:, pages_limit:)
        @file_path   = file_path
        @basename    = basename
        @dpi         = Integer(dpi)
        @max_width   = Integer(max_width)
        @quality     = Integer(quality)
        @pages_limit = Integer(pages_limit)
      end

      def call
        return error("file_not_found") unless File.exist?(@file_path)

        out_dir = Dir.mktmpdir("pdf_jpegs_")
        images =
          if pdftoppm_available?
            render_with_pdftoppm(out_dir)
          else
            render_with_imagemagick(out_dir)
          end

        return error("no_images") if images.empty?

        # Pós-processamento com API de alto nível (mais estável que Tool::Mogrify)
        images.each do |img_path|
          begin
            image = MiniMagick::Image.open(img_path)
            # Redimensiona pela largura (mantém proporção)
            image.resize "#{@max_width}x"
            image.quality @quality.to_s
            image.write img_path
          rescue => e
            Rails.logger.warn("[ToJpeg] image resize failed: #{e.message}") if defined?(Rails)
            # segue o baile, não derruba a importação
          end
        end

        ok(images, out_dir)
      rescue => e
        error(e.message)
      end

      private

      def pdftoppm_available?
        system("command -v pdftoppm >/dev/null 2>&1")
      end

      def render_with_pdftoppm(out_dir)
        base = File.join(out_dir, @basename)
        last = @pages_limit
        cmd = %(pdftoppm -f 1 -l #{last} -rx #{@dpi} -ry #{@dpi} -jpeg -jpegopt quality=#{@quality} "#{@file_path}" "#{base}")
        ok = system(cmd)
        return [] unless ok
        Dir[File.join(out_dir, "#{@basename}-*.jpg")].sort
      end

      def render_with_imagemagick(out_dir)
        # Fallback simples com `convert`. Usamos a Tool::Convert, mas sem pós “mogrify”.
        out_pattern = File.join(out_dir, "#{@basename}-%02d.jpg")
        pages = @pages_limit
        range = "[0-#{pages - 1}]"

        begin
          MiniMagick::Tool::Convert.new do |convert|
            convert.density(@dpi.to_s)
            convert << "#{@file_path}#{range}"
            convert.quality(@quality.to_s)
            convert << out_pattern
          end
        rescue ArgumentError
          # Algumas instalações preferem o wrapper Magick
          MiniMagick::Tool::Magick.new do |magick|
            magick.convert
            magick.density(@dpi.to_s)
            magick << "#{@file_path}#{range}"
            magick.quality(@quality.to_s)
            magick << out_pattern
          end
        end

        Dir[File.join(out_dir, "#{@basename}-*.jpg")].sort
      end

      def ok(images, dir)
        { ok: true, images:, dir: }
      end

      def error(message)
        { ok: false, message: }
      end
    end
  end
end
