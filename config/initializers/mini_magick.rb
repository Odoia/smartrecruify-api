# config/initializers/mini_magick.rb
# frozen_string_literal: true

require "mini_magick"

MiniMagick.configure do |config|
  config.timeout = Integer(ENV.fetch("MINIMAGICK_TIMEOUT", 60))
end

# --- Validate ImageMagick installation ---
begin
  version = MiniMagick.cli_version
  Rails.logger.info "[MiniMagick] Detected ImageMagick version #{version}"
rescue => e
  Rails.logger.error "[MiniMagick] ERROR: ImageMagick is not installed or not available in PATH. Please install 'imagemagick' (or 'graphicsmagick')."
  Rails.logger.error "[MiniMagick] Original error: #{e.message}"
  raise e
end
