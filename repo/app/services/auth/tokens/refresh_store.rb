# frozen_string_literal: true

# app/services/auth/tokens/refresh_store.rb
module Auth
  module Tokens
    class RefreshStore
      def write(*)
        raise NotImplementedError
      end

      def read(*)
        raise NotImplementedError
      end

      def delete(*)
        raise NotImplementedError
      end
    end
  end
end

