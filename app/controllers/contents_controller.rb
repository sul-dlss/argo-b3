# frozen_string_literal: true

# Controller for managing content (structural)
class ContentsController < ContentsApplicationController
  skip_verify_authorized only: %i[update show]

  def show
    verified_content_id = verify_token(params[:id])
    @content = Content.with_structural_associations.find(verified_content_id)
  end

  def edit
    druid = params[:id]
    cocina_object = Sdr::Repository.find(druid:)
    cache_cocina_hash(cocina_object:)
    authorize! cocina_object, with: ItemPolicy

    @content = find_or_create_content(cocina_object:)
    @solr_doc = fetch_solr_doc(druid:)
    @content_token = generate_token(@content.id)
  end

  def update
    verified_content_id = verify_token(params[:id])
    content = Content.find(verified_content_id)
    build_content_file_binaries(content:)

    head :ok
  end

  private

  def build_content_file_binaries(content:)
    Contents::BinaryBuilder.call(content:, files: params[:content][:files], paths: params[:content][:paths])
  end

  def find_or_create_content(cocina_object:)
    Content.find_by(druid: cocina_object.externalIdentifier, lock: cocina_object.lock, immutable: false) ||
      Contents::Builder.call(cocina_object:, immutable: false)
  end

  def fetch_solr_doc(druid:)
    solr_doc = Sdr::Repository.find_solr(druid:)
    SolrDocPresenter.new(solr_doc:)
  end
end
