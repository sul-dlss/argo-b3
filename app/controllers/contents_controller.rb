# frozen_string_literal: true

# Controller for managing content (structural)
class ContentsController < ApplicationController
  COCINA_HASH_EXPIRATION = 1.hour

  skip_verify_authorized only: %i[update show]

  include TokenConcern

  # The strategy is to authorize on edit, but not repeat authorization for update.
  self.token_purpose = 'contents'

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
    cocina_object = CocinaSupport.build_from_cocina_hash(fetch_cocina_hash(druid: content.druid, lock: content.lock))

    Contents::FileUpdater.call(content:, cocina_object:, files: params[:content][:files],
                               paths: params[:content][:paths])

    head :ok
  end

  private

  def find_or_create_content(cocina_object:)
    Content.find_by(druid: cocina_object.externalIdentifier, lock: cocina_object.lock, immutable: false) ||
      Contents::Builder.call(cocina_object:, immutable: false)
  end

  def fetch_solr_doc(druid:)
    solr_doc = Sdr::Repository.find_solr(druid:)
    SolrDocPresenter.new(solr_doc:)
  end

  def fetch_cocina_hash(druid:, lock:)
    cache_key = "contents/cocina-hash/#{druid}/#{lock}"
    Rails.cache.fetch(cache_key, expires_in: COCINA_HASH_EXPIRATION) do
      cocina_object = Sdr::Repository.find(druid:)
      CacheSupport.cacheable_cocina_object(cocina_object:)
    end
  end

  def cache_cocina_hash(cocina_object:)
    cache_key = "contents/cocina-hash/#{cocina_object.externalIdentifier}/#{cocina_object.lock}"
    Rails.cache.write(cache_key, CacheSupport.cacheable_cocina_object(cocina_object:),
                      expires_in: COCINA_HASH_EXPIRATION)
  end
end
