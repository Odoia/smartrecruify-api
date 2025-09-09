class ApplicationController < ActionController::API
  include Auth::AccessGuard
end
