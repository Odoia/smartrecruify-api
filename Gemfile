source "https://rubygems.org"

ruby "3.4.5"

# --------------------------------------
# Rails Core
# --------------------------------------
gem "rails", "~> 8.0.2", ">= 8.0.2.1"
gem "pg", "~> 1.1"                     # PostgreSQL
gem "puma", ">= 5.0"                   # Puma web server
gem "bootsnap", require: false         # Caching to speed up boot time

# --------------------------------------
# API & Authentication
# --------------------------------------
gem "devise", "~> 4.9"                 # Authentication
gem "devise-jwt", "~> 0.12.1"          # JWT integration for Devise
gem "rack-cors", "~> 3.0"              # CORS support
gem "redis", "~> 5.4"                  # Redis for denylist, cache, and background jobs

# --------------------------------------
# API Documentation
# --------------------------------------
gem "rswag-api", "~> 2.16"
gem "rswag-ui", "~> 2.16"
gem "rswag-specs", "~> 2.16"

# --------------------------------------
# Rails 8 Features (Background Jobs, Caching, WebSockets)
# --------------------------------------
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# --------------------------------------
# Deployment & Performance
# --------------------------------------
gem "kamal", require: false            # Containerized deployment
gem "thruster", require: false         # Puma performance tuning

# --------------------------------------
# IA
# --------------------------------------
gem "ruby-openai", require: "openai"

# --------------------------------------
# PDF
# --------------------------------------
gem "pdf-reader"

# --------------------------------------
# Development & Test
# --------------------------------------
group :development, :test do
  # Testing frameworks
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails", "~> 6.5"
  gem "faker", "~> 3.5"

  # Environment variables
  gem "dotenv-rails"

  # Debugging & code quality tools
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false             # Security analysis
  gem "rubocop-rails-omakase", require: false # Rails style guide
  #debug
  gem 'pry'
end

# --------------------------------------
# Windows / JRuby compatibility
# --------------------------------------
gem "tzinfo-data", platforms: %i[windows jruby]
