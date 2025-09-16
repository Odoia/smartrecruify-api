# frozen_string_literal: true

class DocumentsController < ApplicationController
  before_action :authenticate_user!

  # POST /documents
  # Params:
  #   file     -> uploaded file (required)
  #   dry_run  -> boolean (optional)
  #   debug    -> boolean (optional)
  def create
    file   = params[:file]
    dry    = ActiveModel::Type::Boolean.new.cast(params[:dry_run])
    debug  = ActiveModel::Type::Boolean.new.cast(params[:debug])

    return render json: { ok: false, error: "file_missing" }, status: :unprocessable_content if file.blank?

    # catálogo de cursos enxuto para o prompt
    courses = Course.order(Arel.sql("LOWER(provider), LOWER(name)")).limit(50)
    catalog = courses.map { |c| [c.provider, c.name, c.hours].compact.join(" | ") }

    result = ::Documents::Handler.call(
      file:            file,
      user:            current_user,
      dry_run:         dry,
      course_catalog:  catalog
    )

    if result[:ok]
      payload = debug ? result.merge(meta: (result[:meta] || {}).merge(debug: { dry_run: dry })) : result
      render json: payload, status: :ok
    else
      code = (result[:error].to_s == "import_failed" ? :internal_server_error : :unprocessable_content)
      render json: result, status: code
    end
  rescue => e
    render json: { ok: false, error: "import_failed", message: e.message }, status: :internal_server_error
  end
end
