# frozen_string_literal: true

# Controller for objects (DRO, collection, admin policy)
class ObjectsController < ApplicationController
  skip_verify_authorized only: %i[show_json show_workflows show_overview show_header show_versions
                                  show_purl_preview show_solr_doc show_files]

  include TokenConcern

  # The strategy is to authorize on show, but not repeat authorization on other show endpoints.
  # This avoids having to make additional calls that would be required for the authorization, but not the showing.
  # For the other show endpoints, the druid is signed and verified to ensure that the druid is valid and was generated
  # by the show action.
  # Thus, the signing / verification acts as authorization for those endpoints.
  self.token_purpose = 'show'

  # Note that for the purposes of rendering show pages, both @solr_doc or @cocina_models
  # provide the latest object data. (This is a "live" solr document, not the possibly dated version stored in Solr.)
  #
  # The lock is fetched once here (a lightweight request) and used to decide whether the solr doc and
  # cocina hash caches (shared with the show_* turbo frame actions below) need to be refreshed. This
  # keeps the frame actions themselves unaware of the lock: they just read whatever is in the cache,
  # trusting that this action (which always runs moments before them, as the parent page load) has
  # already made it fresh.
  def show
    druid = params[:druid]
    lock = Sdr::Repository.lock(druid:)

    @solr_doc = SolrDocPresenter.new(solr_doc: refresh_solr_doc(druid, lock))
    authorize! @solr_doc, with: ObjectPolicy

    refresh_cocina_hash(druid, lock) # Warm the cache for the other frames (e.g., overview, json, purl_preview).

    set_from_last_search_cookie # This provides @last_search_form
    @druid_token = generate_token(druid)
    @version_service = Sdr::VersionService.new(druid:)
  end

  def show_header
    @solr_doc = SolrDocPresenter.new(solr_doc: fetch_solr_doc(verified_druid))

    render layout: false
  end

  def show_overview
    @solr_doc = SolrDocPresenter.new(solr_doc: fetch_solr_doc(verified_druid))
    @cocina_model = CocinaModels::PresenterFactory.build_from_cocina_hash(fetch_cocina_hash(verified_druid))

    case @solr_doc.object_type
    when 'collection'
      render :show_collection_overview, layout: false
    when 'adminPolicy'
      render :show_admin_policy_overview, layout: false
    else
      # This also includes agreements and virtual objects.
      render :show_dro_overview, layout: false
    end
  end

  def show_json
    @cocina_hash = fetch_cocina_hash(verified_druid)

    render layout: false
  end

  def show_workflows
    @druid = verified_druid
    @workflows = Sdr::WorkflowService.workflows_for(druid: @druid)

    render layout: false
  end

  def show_versions
    @druid = verified_druid
    object_client = Dor::Services::Client.object(@druid)
    @versions_presenter = VersionsPresenter.new(version_inventory: object_client.version.inventory,
                                                milestones: object_client.milestones.list,
                                                user_version_inventory: object_client.user_version.inventory)
  end

  def show_solr_doc
    @solr_doc_hash = fetch_solr_doc(verified_druid)

    render layout: false
  end

  def show_purl_preview
    @cocina_hash = fetch_cocina_hash(verified_druid)
    @preview = fetch_purl_preview(@cocina_hash)
    render layout: false
  end

  def show_files
    @content = fetch_content(verified_druid)

    render layout: false
  end

  private

  def verified_druid
    @verified_druid ||= verify_token(params[:druid])
  end

  # Note that this is a "live" solr document built from latest DSA data.
  def fetch_solr_doc(druid)
    Rails.cache.fetch(solr_doc_cache_key(druid), expires_in: solr_doc_cache_expires_in) do
      { lock: nil, value: Sdr::Repository.find_solr(druid:) }
    end.fetch(:value)
  end

  def fetch_cocina_hash(druid)
    Rails.cache.fetch(cocina_hash_cache_key(druid), expires_in: 1.hour) do
      { lock: nil, value: compute_cocina_hash(druid) }
    end.fetch(:value)
  end

  # Refreshes the cached solr doc if the lock has changed (or the cache is empty), used only by #show.
  # A short TTL is kept as a safety net, since the solr doc can change independently of the lock.
  def refresh_solr_doc(druid, lock)
    cache_key = solr_doc_cache_key(druid)
    cached = Rails.cache.read(cache_key)
    return cached[:value] if cached && cached[:lock] == lock

    value = Sdr::Repository.find_solr(druid:)
    Rails.cache.write(cache_key, { lock:, value: }, expires_in: solr_doc_cache_expires_in)
    value
  end

  # Refreshes the cached cocina hash if the lock has changed (or the cache is empty), used only by #show.
  # The TTL here is just a safety net: freshness is driven by the lock check, not the TTL.
  def refresh_cocina_hash(druid, lock)
    cache_key = cocina_hash_cache_key(druid)
    cached = Rails.cache.read(cache_key)
    return cached[:value] if cached && cached[:lock] == lock

    value = compute_cocina_hash(druid)
    Rails.cache.write(cache_key, { lock:, value: }, expires_in: 1.hour)
    value
  end

  def compute_cocina_hash(druid)
    cocina_object = Sdr::Repository.find(druid:)
    CocinaDisplay::Utils.deep_compact_blank(cocina_object.to_h, preserve_keys: [:label])
  end

  def solr_doc_cache_key(druid)
    "objects/solr-doc/#{druid}"
  end

  def cocina_hash_cache_key(druid)
    "objects/cocina-hash/#{druid}"
  end

  def solr_doc_cache_expires_in
    (Settings.reload_intervals.cocina_model / 1000.0).seconds - 1.second
  end

  def fetch_purl_preview(cocina_hash)
    body = Rails.cache.fetch("objects/purl-preview/#{cocina_hash[:externalIdentifier]}/#{cocina_hash[:lock]}",
                             expires_in: 1.hour) do
      PurlPreviewService.call(cocina_hash:)
    end
    Nokogiri::HTML(body).css('main').inner_html.html_safe # rubocop:disable Rails/OutputSafety
  rescue PurlPreviewService::Error => e
    Honeybadger.notify(e, context: { cocina_hash: })
    nil
  end

  def fetch_content(druid)
    cocina_object = CocinaSupport.build_from_cocina_hash(fetch_cocina_hash(druid))
    Content.find_by(druid:, lock: cocina_object.lock, immutable: true) ||
      Contents::Builder.call(cocina_object:)
  end
end
