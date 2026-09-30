# frozen_string_literal: true

# Controller for looking up the title of a catalog record, e.g., for the "Retrieve title" button
# on the description tab of the item form.
class CatalogTitlesController < ApplicationController
  # Catalog records are not access controlled, so any authenticated user may look up a title.
  skip_verify_authorized

  def index
    return render_error(:blank, :unprocessable_content) if catalog_record_id.blank?

    title = CatalogRepository.title(catalog_record_id:)
    return render_error(:not_found, :not_found) if title.blank?

    render json: { title: }
  rescue CatalogRepository::NotFoundResponse
    render_error(:not_found, :not_found)
  rescue CatalogRepository::Error
    render_error(:catalog_error, :bad_gateway)
  end

  private

  def catalog_record_id
    params[:catalog_record_id].to_s.strip
  end

  def render_error(key, status)
    render json: { error: t("edit.items.fields.catalog_record_id.errors.#{key}") }, status:
  end
end
