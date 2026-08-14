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
    @content = Content.find(verified_content_id)
  end

  def edit
    druid = params[:id]
    cocina_object = Sdr::Repository.find(druid:)
    cache_cocina_hash(cocina_object:)
    authorize! cocina_object, with: ItemPolicy

    @content = find_or_create_content(cocina_object:)
    @solr_doc = Sdr::Repository.find_solr(druid:)

    @solr_doc = fetch_solr_doc(druid:)
    @content_token = generate_token(@content.id)
  end

  def update
    verified_content_id = verify_token(params[:id])
    @content = Content.find(verified_content_id)
    @cocina_object = CocinaSupport.build_from_cocina_hash(fetch_cocina_hash(druid: @content.druid, lock: @content.lock))

    update_files

    head :ok
  end

  private

  def find_or_create_content(cocina_object:)
    Content.find_by(druid: cocina_object.externalIdentifier, lock: cocina_object.lock) ||
      Contents::Builder.call(cocina_object:)
  end

  def fetch_solr_doc(druid:)
    solr_doc = Sdr::Repository.find_solr(druid:)
    SolrDocPresenter.new(solr_doc:)
  end

  def update_files
    files = params[:content][:files]
    files.each do |index, file|
      # Dropzone controller is modified to provide the full path as content[:paths][index]
      filepath = params[:content][:paths][index]
      # next if IgnoreFileService.call(filepath:)

      content_file_set = @content.content_file_sets.create(file_set_type: 'object',
                                                           label: '')
      content_file_binary = find_or_build_content_file_binary(filepath:)
      attach_file(content_file_binary:, file:)
      content_file_set.content_files.create!(content_file_binary:, **file_params)
    end
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

  def find_or_build_content_file_binary(filepath:)
    @content.content_file_binaries.find_by(filepath:) ||
      @content.content_file_binaries.build(filepath:)
  end

  def attach_file(content_file_binary:, file:)
    content_file_binary.file_location = :attached
    content_file_binary.size = file.size
    content_file_binary.sha1_digest = nil
    content_file_binary.md5_digest = nil
    content_file_binary.save!
    content_file_binary.file.attach(file)
  end

  def file_params
    access = @cocina_object.access.embargo.presence || @cocina_object.access
    {
      label: '',
      preserve: true,
      publish: true,
      shelve: true,
      view: access.view == 'citation-only' ? 'dark' : access.view,
      download: access.download,
      location: access.location
    }
  end
end
