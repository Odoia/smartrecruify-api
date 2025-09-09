# frozen_string_literal: true

require 'rails_helper'

# spec/swagger_helper.rb
RSpec.configure do |config|
  config.swagger_root = Rails.root.join('swagger').to_s

  config.swagger_docs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: { title: 'SmartRecruify API', version: 'v1' },
      components: {
        securitySchemes: {
          Bearer: {
            type: :http, scheme: :bearer, bearerFormat: :JWT
          }
        }
      },
      security: [{ Bearer: [] }],
      paths: {}
    }
  }

  config.swagger_format = :yaml
end
