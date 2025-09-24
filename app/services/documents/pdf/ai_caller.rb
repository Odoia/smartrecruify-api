# frozen_string_literal: true

require "openai"
require "json"

module Documents
  module Pdf
    class AiCaller
      def initialize(prompt:, mode: :vision, model: ENV["LLM_MODEL"].presence || "gpt-4o-mini")
        @prompt = prompt || {}
        @mode   = mode.to_sym
        @model  = model
      end

      def call
        validate_prompt!

        messages =
          case mode
          when :vision
            images = Array(prompt.dig(:input, :images))
            [
              { role: "system", content: prompt[:system].to_s },
              { role: "user",   content: vision_content(images, prompt[:user_text].to_s) }
            ]
          when :text
            text = prompt.dig(:input, :text).to_s
            [
              { role: "system", content: prompt[:system].to_s },
              { role: "user",   content: [prompt[:user_text].to_s, text].join("\n\n").strip }
            ]
          else
            raise ArgumentError, "unsupported_mode: #{mode.inspect}"
          end

        resp = chat_with_openai!(messages)
        content = resp.dig("choices", 0, "message", "content").to_s
        raise "empty_ai_response" if content.strip.empty?

        JSON.parse(content) # retorna Hash com chaves string (Sanitize pode lidar)
      rescue JSON::ParserError => e
        Rails.logger.error("[AI] invalid JSON: #{e.message}") if defined?(Rails)
        raise "ai_parse_failed: invalid_json: #{e.message}"
      end

      private

      attr_reader :prompt, :mode, :model

      def chat_with_openai!(messages)
        access_token = ENV["OPENAI_API_KEY"].to_s
        raise ArgumentError, "missing_openai_api_key" if access_token.empty?

        client = OpenAI::Client.new(access_token: access_token)
        params = {
          model: model,
          temperature: 0,
          response_format: { type: "json_object" },
          messages: messages
        }

        Rails.logger.info("[AI] model=#{model} mode=#{mode} msgs=#{messages.size}") if defined?(Rails)
        client.chat(parameters: params)
      end

      def validate_prompt!
        raise ArgumentError, "prompt_must_be_hash" unless prompt.is_a?(Hash)
        raise ArgumentError, "missing_system"      if prompt[:system].to_s.strip.empty?
        raise ArgumentError, "missing_input"       if prompt[:input].nil?

        case mode
        when :vision
          imgs = Array(prompt.dig(:input, :images))
          raise ArgumentError, "missing_images" if imgs.empty?
        when :text
          txt = prompt.dig(:input, :text).to_s
          raise ArgumentError, "missing_text" if txt.strip.empty?
        end
      end

      def vision_content(images, user_text)
        content = []
        content << { type: "text", text: user_text } unless user_text.to_s.strip.empty?
        images.each do |data_url|
          content << { type: "image_url", image_url: { url: data_url.to_s, detail: "high" } }
        end
        content
      end
    end
  end
end
