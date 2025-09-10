# frozen_string_literal: true

require "rack/cors"

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:3001"
    resource "*",
      headers: :any,
      expose: %w[Authorization],   # expõe o header para o browser ler
      methods: %i[get post put patch delete options head],
      credentials: true            # permite cookies (refresh)
  end
end
