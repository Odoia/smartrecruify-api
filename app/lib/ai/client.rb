# frozen_string_literal: true

module Ai
  # app/lib/ai/client.rb
  class Client
    DEFAULT_MODEL   = ENV.fetch("LLM_MODEL", "gpt-4o-mini")
    DEFAULT_TIMEOUT = Integer(ENV.fetch("OPENAI_TIMEOUT", 240)) # segundos

    def self.client
      @client ||= OpenAI::Client.new(
        access_token: ENV.fetch("OPENAI_API_KEY"),
        request_timeout: DEFAULT_TIMEOUT
      )
    end

    def self.model
      DEFAULT_MODEL
    end

    def self.chat(messages:, model: DEFAULT_MODEL, **opts)
      client.chat(
        parameters: {
          model: model,
          messages: messages,
          temperature: 0,
          **opts
        }
      )
    end
  end
end
