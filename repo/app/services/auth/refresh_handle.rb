# frozen_string_literal: true

module Auth
# app/services/auth/refresh_handle.rb
  class RefreshHandle
    def initialize(
      store:  Auth::Tokens::Adapters::RefreshStoreRedis.new,
      cookie: Auth::Refresh::Cookie.new
    )
      @issue  = Auth::Refresh::Issue.new(store: store, cookie: cookie)
      @rotate = Auth::Refresh::Rotate.new(store: store, cookie: cookie)
      @revoke = Auth::Refresh::Revoke.new(store: store, cookie: cookie)
    end

    def issue_for(user:, response:)   = @issue.call(user: user, response: response)
    def rotate(request:, response:)   = @rotate.call(request: request, response: response)
    def revoke(request:, response:)   = @revoke.call(request: request, response: response)
  end
end
