# config/application.rb
require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Load .env variables early in non-production (use credentials/ENV in production)
require "dotenv/load" if ENV["RAILS_ENV"] != "production"

# Require gems listed in Gemfile, including any gems limited to environments
Bundler.require(*Rails.groups)

module SmartrecruifyApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Only load a smaller set of middleware suitable for API-only apps.
    # Middleware like session, flash, cookies can be added back manually.
    config.api_only = true

    # config.middleware.use ActionDispatch::Cookies
    config.middleware.use Warden::JWTAuth::Middleware

    # Autoload from lib/, but ignore non-Ruby subfolders
    config.autoload_lib(ignore: %w[assets tasks])

    # Example: set your app’s default time zone (optional)
    # config.time_zone = "UTC"

    # Example: eager load additional paths (optional)
    # config.eager_load_paths << Rails.root.join("extras")

    # If you want to silence generators for views/helpers (API-only already skips most)
    # config.generators do |g|
    #   g.helper false
    #   g.assets false
    #   g.test_framework :rspec
    # end
  end
end
