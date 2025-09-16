# frozen_string_literal: true

module Ai
  class Client
    DEFAULT_MODEL = "gpt-4o-mini"

    def initialize(client: OpenAIClient)
      @client = client
    end

    # Gera JSON a partir de um prompt + texto
    def json_extract!(prompt:, input_text:, schema:, max_tokens: 1500, temperature: 0.2)
      response = @client.chat(
        parameters: {
          model: DEFAULT_MODEL,
          messages: [
            { role: "system", content: "Você é um extrator de dados. Responda SOMENTE em JSON válido, sem explicações." },
            { role: "user", content: prompt },
            { role: "user", content: input_text }
          ],
          temperature: temperature,
          max_tokens: max_tokens,
          response_format: { type: "json_schema", json_schema: schema }
        }
      )

      raw = response.dig("choices", 0, "message", "content")
      JSON.parse(raw)
    rescue JSON::ParserError => e
      raise "AI JSON parse error: #{e.message}"
    end
  end
end
