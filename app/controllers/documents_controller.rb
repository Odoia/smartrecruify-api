# frozen_string_literal: true

# app/controllers/documents_controller.rb
class DocumentsController < ApplicationController
  include Auth::AccessGuard
  before_action :require_user!

  # POST /documents
  # Params: file (PDF). Sem persistência.
  def create
    file = params.require(:file)

    payload = Documents::Pdf::Orchestrator.new(
      file: file,
      user: current_user,
      include_catalog: true
    ).call

    render json: { ok: true, payload: payload }, status: :ok
  rescue ActionController::ParameterMissing
    render json: { ok: false, error: "missing_file_param" }, status: :bad_request
  rescue => e
    Rails.logger.error("[DOCUMENTS#create] #{e.class}: #{e.message}")
    render json: { ok: false, error: e.message }, status: :unprocessable_content
  end

  private

  def require_user!
    head :unauthorized unless current_user
  end
end
