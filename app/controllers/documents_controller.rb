# frozen_string_literal: true

# app/controllers/documents_controller.rb
class DocumentsController < ApplicationController
  include Auth::AccessGuard
  before_action :require_user!

  # POST /documents
  # Params:
  #   - file: PDF (obrigatório)
  #   - dry_run: boolean (default: true) -> se false, persiste education + employment
  #
  # Resposta:
  #   {
  #     ok: true,
  #     payload: { ...sanitizado... },
  #     persist: { ok: true, results: { education: {...}, employment: {...} } } # quando dry_run=false
  #   }
  def create
    file    = params.require(:file)
    dry_run = ActiveModel::Type::Boolean.new.cast(params[:dry_run].presence || true)

    payload = Documents::Pdf::Orchestrator.new(
      file: file,
      user: current_user,
      include_catalog: true
    ).call

    # if dry_run
    #   render json: { ok: true, payload: payload }, status: :ok
    #   return
    # end

    persist_result = Documents::Persisters::Handler.new(
      user_id: current_user.id,
      payload: payload
    ).call

    render json: { ok: true, payload: payload, persist: persist_result }, status: :ok
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
