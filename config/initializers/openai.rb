# frozen_string_literal: true

OpenAIClient = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
