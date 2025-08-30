# frozen_string_literal: true

# app/services/auth/refresh_handle.rb
module Auth
  class RefreshHandle
    def initialize(
      store: Auth::Tokens::Adapters::RefreshStoreRedis.new,
      cookie: Auth::Refresh::Cookie.new
    )
      @issue  = Auth::Refresh::Issue.new(store:, cookie:)
      @rotate = Auth::Refresh::Rotate.new(store:, cookie:)
      @revoke = Auth::Refresh::Revoke.new(store:, cookie:)
    end

    def issue_for(user:, response:)
      @issue.call(user:, response:)
    end

    def rotate(request:, response:)
      @rotate.call(request:, response:)
    end

    def revoke(request:, response:)
      @revoke.call(request:, response:)
    end
  end
end
