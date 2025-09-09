# frozen_string_literal: true
require "redis"

class JwtRedisDenylist
  NS = "jwt:denylist"

  def self.redis
    @redis ||= Redis.new(url: ENV.fetch("REDIS_URL"))
  end

  def self.revoke_jwt(payload, user)
    jti = payload["jti"]
    exp = payload["exp"]
    return unless jti && exp

    ttl = exp.to_i - Time.now.to_i
    return if ttl <= 0

    redis.setex("#{NS}:#{jti}", ttl, user.id)
  rescue => e
    Rails.logger.error("[JWT] revoke_jwt failed: #{e.class}: #{e.message}")
  end

  def self.jwt_revoked?(payload, _user)
    jti = payload["jti"]
    return false unless jti
    redis.exists?("#{NS}:#{jti}")
  rescue => e
    Rails.logger.error("[JWT] jwt_revoked? error: #{e.class}: #{e.message}")
    true 
  end
end
