# frozen_string_literal: true

require "redis"
require "json"

module Auth
  module Tokens
    module Adapters
      class AccessStoreRedis
        def initialize(redis: nil)
          @redis = redis || Redis.new(url: ENV.fetch("REDIS_URL"))
        end

        def put!(payload)
          jti, sub, exp = payload.values_at("jti", "sub", "exp")
          raise ArgumentError, "missing jti/sub/exp" if [jti, sub, exp].any?(&:nil?)

          ttl = [exp.to_i - Time.now.to_i, 0].max
          @redis.set(key_for(jti), { "sub" => sub, "exp" => exp }.to_json, ex: ttl)
          true
        end

        def exists?(payload)
          jti = payload["jti"]
          return false if jti.nil?

          exists = @redis.exists?(key_for(jti))
          (exists.is_a?(Integer) ? exists : (exists ? 1 : 0)) == 1
        end

        def delete!(payload)
          jti = payload["jti"]
          return false if jti.nil?

          @redis.del(key_for(jti)) > 0
        end

        private

        def key_for(jti)
          "access:#{jti}"
        end
      end
    end
  end
end
