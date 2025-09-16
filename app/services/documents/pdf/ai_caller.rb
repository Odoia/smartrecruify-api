# frozen_string_literal: true

require "openai"

module Documents
  module Pdf
    class AiCaller
      def self.call(prompt:, mode:)
        new(prompt:, mode:).call
      end

      def initialize(prompt:, mode:)
        @prompt = prompt || {}
        @mode   = (mode || :text).to_sym
      end

      def call
        validate_prompt!

        messages =
          if @mode == :vision
            images = Array(@prompt.dig(:input, :images))
            [
              { role: "system", content: @prompt[:system].to_s },
              { role: "user",   content: vision_content(images, @prompt[:user_text].to_s) }
            ]
          else
            text = @prompt.dig(:input, :text).to_s
            [
              { role: "system", content: @prompt[:system].to_s },
              { role: "user",   content: text_with_user_prefix(@prompt[:user_text], text) }
            ]
          end

        resp = chat_with_openai!(messages)

        content = resp.dig("choices", 0, "message", "content")
        raise ArgumentError, "empty_ai_response" if content.to_s.strip.empty?

        JSON.parse(content, symbolize_names: true)
      rescue JSON::ParserError => e
        Rails.logger.error("[AI] JSON parse error: #{e.message}")
        raise "ai_parse_failed: invalid_json: #{e.message}"
      rescue ArgumentError => e
        Rails.logger.error("[AI] Argument error: #{e.message}\n#{(e.backtrace || [])[0,5].join("\n")}")
        raise "ai_parse_failed: #{e.message}"
      rescue => e
        Rails.logger.error("[AI] [48;79;156;1343;1248tUnexpected #{e.class}: #{e.message}\n#{(e.backtrace || [])[0,5].join("\n")}")
        raise "ai_parse_failed: #{e.message}"
      end

      private

      def chat_with_openai!(messages)
        access_token = ENV["OPENAI_API_KEY"].to_s
        raise ArgumentError, "missing_openai_api_key" if access_token.empty?

        client = OpenAI::Client.new(access_token: access_token)

        model = ENV["LLM_MODEL"].presence || "gpt-4o-mini"
        params = {
          model: model,
          temperature: 0,
          response_format: { type: "json_object" },
          messages: messages
        }

        # Log de sanidade
        Rails.logger.info(
          "[AI] local_client model=#{model} mode=#{@mode} messages=#{messages.size} " \
          "sys_len=#{@prompt[:system].to_s.length} user_hint_len=#{@prompt[:user_text].to_s.length}"
        )

        # A gem oficial usa keyword :parameters
        client.chat(parameters: params)
      end

      def validate_prompt!
        raise ArgumentError, "prompt_must_be_hash" unless @prompt.is_a?(Hash)
        raise ArgumentError, "missing_system"      if @prompt[:system].to_s.strip.empty?
        raise ArgumentError, "missing_input"       if @prompt[:input].nil?

        case @mode
        when :vision
          imgs = Array(@prompt.dig(:input, :images))
          raise ArgumentError, "missing_images" if imgs.empty?
        when :text
          txt = @prompt.dig(:input, :text).to_s
          raise ArgumentError, "missing_text" if txt.strip.empty?
        else
          raise ArgumentError, "unsupported_mode: #{@mode.inspect}"
        end
      end

      def vision_content(images, user_text)
        # Estrutura multimodal aceita pelo ruby-openai: [{type:"text"}, {type:"image_url", image_url:{url: ...}}]
        content = []
        content << { type: "text", text: user_text } unless user_text.empty?
        images.each do |data_url|
          content << { type: "image_url", image_url: { url: data_url.to_s } }
        end
        content
      end

      def text_with_user_prefix(user_text, text)
        [user_text.to_s, text.to_s].join("\n\n").strip
      end
    end
  end
end
