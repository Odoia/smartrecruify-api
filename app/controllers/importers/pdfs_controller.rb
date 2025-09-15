# app/controllers/importers/pdfs_controller.rb
class Importers::PdfsController < ApplicationController
  before_action :authenticate_user!

  # POST /importers/pdfs
  # Params:
  #   file   -> PDF file (required)
  #   dry_run -> boolean (optional)
  #   source -> "auto" | "linkedin" | "cv" (default: "auto")
  def create
    file   = params[:file]
    dry    = ActiveModel::Type::Boolean.new.cast(params[:dry_run])
    source = (params[:source].presence || "auto").to_s.downcase.to_sym

    return render json: { ok: false, error: "file_missing" }, status: :unprocessable_content if file.blank?

    result = Importers::Pdf::Import.call(file: file, user: current_user, dry_run: dry, source: source)

    if result[:ok]
      render json: result, status: :ok
    else
      code = (result[:error] == "import_failed" ? :internal_server_error : :unprocessable_content)
      render json: result, status: code
    end
  rescue => e
    render json: { ok: false, error: "import_failed", message: e.message }, status: :internal_server_error
  end
end
