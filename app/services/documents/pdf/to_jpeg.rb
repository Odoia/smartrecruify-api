# frozen_string_literal: true
require "mini_magick"
require "fileutils"

module Documents
  module Pdf
    # app/services/documents/pdf/to_jpeg.rb
    class ToJpeg
      def initialize(file:, basename: "page", dpi: 150, max_width: 1600, quality: 85, pages_limit: 6)
        @file         = file
        @basename     = basename
        @dpi          = Integer(dpi)
        @max_width    = Integer(max_width)
        @quality      = Integer(quality)
        @pages_limit  = Integer(pages_limit)
      end

      # Retorna: Array<String> com os paths dos JPEGs (uma entrada por página)
      # Em falha: retorna [] (o chamador decide o que fazer)
      def call
        path = ensure_path!
        return [] unless File.exist?(path)

        out_dir = Dir.mktmpdir("pdf_jpegs_")
        images  = pdftoppm_available? ? render_with_pdftoppm(path, out_dir) : render_with_imagemagick(path, out_dir)
        return [] if images.empty?

        postprocess(images) # resize + quality
        images
      rescue => e
        Rails.logger.warn("[Pdf::ToJpeg] #{e.class}: #{e.message}") if defined?(Rails)
        []
      end

      private

      attr_reader :file, :basename, :dpi, :max_width, :quality, :pages_limit

      # --- helpers ---

      def ensure_path!
        # UploadedFile (ActionDispatch) tem #path, mas nem sempre o arquivo existe após ler .read
        return file.path if file.respond_to?(:path) && file.path && File.exist?(file.path)
        return file.to_s  if file.is_a?(String) && File.exist?(file.to_s)

        # fallback: escrever bytes temporários (caso tenha vindo um IO)
        dir  = Dir.mktmpdir("pdf_src_")
        name = if file.respond_to?(:original_filename) && file.original_filename.present?
                 file.original_filename
               else
                 "upload.pdf"
               end
        dest = File.join(dir, name)
        bytes = if file.respond_to?(:read) then file.read else file.to_s end
        File.open(dest, "wb") { |f| f.write(bytes) }
        dest
      end

      def pdftoppm_available?
        system("command -v pdftoppm >/dev/null 2>&1")
      end

      def render_with_pdftoppm(src_path, out_dir)
        base = File.join(out_dir, basename)
        last = pages_limit
        cmd  = %(pdftoppm -f 1 -l #{last} -rx #{dpi} -ry #{dpi} -jpeg -jpegopt quality=#{quality} "#{src_path}" "#{base}")
        ok   = system(cmd)
        return [] unless ok
        Dir[File.join(out_dir, "#{basename}-*.jpg")].sort
      end

      def render_with_imagemagick(src_path, out_dir)
        out_pattern = File.join(out_dir, "#{basename}-%02d.jpg")
        range       = "[0-#{pages_limit - 1}]"

        begin
          MiniMagick::Tool::Convert.new do |convert|
            convert.density(dpi.to_s)
            convert << "#{src_path}#{range}"
            convert.quality(quality.to_s)
            convert << out_pattern
          end
        rescue ArgumentError
          MiniMagick::Tool::Magick.new do |magick|
            magick.convert
            magick.density(dpi.to_s)
            magick << "#{src_path}#{range}"
            magick.quality(quality.to_s)
            magick << out_pattern
          end
        end

        Dir[File.join(out_dir, "#{basename}-*.jpg")].sort
      end

      def postprocess(image_paths)
        image_paths.each do |img|
          begin
            image = MiniMagick::Image.open(img)
            image.resize "#{max_width}x"   # mantém proporção
            image.quality quality.to_s
            image.write img
          rescue => e
            Rails.logger.warn("[Pdf::ToJpeg] resize failed for #{img}: #{e.message}") if defined?(Rails)
          end
        end
      end
    end
  end
end
