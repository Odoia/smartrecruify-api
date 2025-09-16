# app/controllers/importers/pdfs_controller.rb
# frozen_string_literal: true

class Importers::PdfsController < ApplicationController
  before_action :authenticate_user!

  # POST /importers/pdfs
  # Params:
  #   file     -> PDF (required, multipart/form-data)
  #   dry_run  -> boolean (optional, default: false)
  #   source   -> "auto" | "linkedin" | "cv" (optional; hoje usamos principalmente linkedin)
  #   debug    -> boolean (optional; inclui meta extra no payload)
  def create
    file   = params[:file]
    dry    = ActiveModel::Type::Boolean.new.cast(params[:dry_run])
    debug  = ActiveModel::Type::Boolean.new.cast(params[:debug])

    source = (params[:source].presence || "auto").to_s.downcase.to_sym
    source = :auto unless %i[auto linkedin cv].include?(source)

    # validações rápidas
    return render json: { ok: false, error: "file_missing" }, status: :unprocessable_content if file.blank?
    return render json: { ok: false, error: "invalid_mime" },  status: :unprocessable_content unless pdf_mime?(file)

    result = ::Importers::Base.call(file: file, user: current_user, dry_run: dry, source: source)

    if result[:ok]
      payload = debug ? result.merge(meta: (result[:meta] || {}).merge(debug: { source: source, dry_run: dry })) : result
      render json: payload, status: :ok
    else
      # erros “de usuário” → 422; erros internos → 500
      code = (result[:error].to_s == "import_failed" ? :internal_server_error : :unprocessable_content)
      render json: result, status: code
    end
  rescue => e
    Rails.logger.error("[Importers::PdfsController] #{e.class}: #{e.message}\n#{Array(e.backtrace).first(5).join("\n")}")
    render json: { ok: false, error: "import_failed", message: e.message }, status: :internal_server_error
  end

  private

  # Aceita os mimes comuns de PDF (alguns navegadores mandam application/octet-stream)
  def pdf_mime?(file)
    mime = file.content_type.to_s
    return true if mime == "application/pdf"
    return true if File.extname(file.original_filename.to_s).downcase == ".pdf"
    false
  end
end
