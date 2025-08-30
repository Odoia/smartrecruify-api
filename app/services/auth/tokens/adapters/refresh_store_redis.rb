# frozen_string_literal: true
require "redis"

module Auth
  module Tokens
    module Adapters
      # app/services/auth/tokens/adapters/refresh_store_redis.rb
      class RefreshStoreRedis
        NS = "refresh:tokens:v1"

        def initialize(redis: default_redis)
          @redis = redis
        end

        def put!(jti:, user_id:, exp:)
          ttl = [exp - Time.now.to_i, 0].max
          @redis.setex(key(jti), ttl, user_id.to_s)
        end

        def fetch_user_id(jti:)
          @redis.get(key(jti))
        end

        def revoke!(jti:)
          @redis.del(key(jti))
        end

        private

        def key(jti) = "#{NS}:#{jti}"

        def default_redis
          url = ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379/0")
          Redis.new(url:)
        end
      end
    end
  end
end
