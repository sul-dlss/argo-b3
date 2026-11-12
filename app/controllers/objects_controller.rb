# frozen_string_literal: true

# Controller for objects (DRO, collection, adminPolicy)
class ObjectsController < ApplicationController # rubocop:disable Metrics/ClassLength
  RECENT_OBJECTS_LIMIT = 5

  skip_verify_authorized only: %i[show_json show_workflows show_overview show_versions show_events show_releases
                                  show_purl_preview show_solr_doc show_files show_structure show_constituents
                                  show_structural_csv show_descriptive_csv track]

  include TokenConcern
  include ToastAndRefreshConcern
  include VersionsTableConcern

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
  # The cached cocina hash omits the file sets (structural.contains), which can be large; frames that need them
  # use the full cocina hash, which is fetched on demand.
  def show # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    druid = druid_param
    lock = Sdr::Repository.lock(druid:)

    @solr_doc = SolrDocPresenter.new(solr_doc: refresh_solr_doc(druid, lock))
    authorize! @solr_doc, with: ObjectPolicy

    # Also warms the cache for the other frames (e.g., overview, json, purl_preview).
    @cocina_object = CocinaSupport.build_from_cocina_hash(refresh_cocina_hash(druid, lock).dup)

    set_from_last_search_cookie # This provides @last_search_form and @total_results
    set_search_navigation
    @druid_token = generate_token(druid)
    version_service = Sdr::VersionService.new(druid:)
    content = Content.latest_staging_activity(druid:)
    @object_status_presenter = ObjectStatusPresenter.new(solr_doc: @solr_doc, version_service:, content:)
    @unsaved_content_changes = unsaved_content_changes?(druid)
    release_tags = @solr_doc.releasable_type? ? Sdr::Repository.release_tags(druid:) : []
    @object_released_presenter = ObjectReleasedPresenter.new(solr_doc: @solr_doc, version_service:, release_tags:)
    @previously_published = republishable?
    @draft_actions_presenter = DraftActionsPresenter.new(cocina_version: @cocina_object.version, version_service:)

    track_recent_object(druid) unless turbo_prefetch?
    @pinned_tags = PinnedTag.where(user: current_user).pluck(:tag).to_set
    @pinned = PinnedObject.exists?(druid:, user: current_user)
  end

  def show_overview
    @solr_doc = SolrDocPresenter.new(solr_doc: fetch_solr_doc(verified_druid))
    @cocina_model = CocinaModels::PresenterFactory.build_from_cocina_hash(fetch_cocina_hash(verified_druid))

    case @solr_doc.object_type
    when 'collection'
      @item_count = Searchers::CollectionItemCount.call(collection_druid: @solr_doc.druid,
                                                        user_scope: current_user_scope)
      render :show_collection_overview, layout: false
    when 'APO'
      @object_counts = Searchers::AdminPolicyObjectCounts.call(admin_policy_druid: @solr_doc.druid,
                                                               user_scope: current_user_scope)
      render :show_admin_policy_overview, layout: false
    else
      # This also includes agreements and virtual objects.
      render :show_dro_overview, layout: false
    end
  end

  def show_json
    @cocina_hash = full_cocina_hash

    render layout: false
  end

  def show_workflows
    @druid = verified_druid
    @workflows = Sdr::WorkflowService.workflows_for(druid: @druid)
    @solr_doc = SolrDocPresenter.new(solr_doc: fetch_solr_doc(@druid))

    render layout: false
  end

  def show_versions
    @druid = verified_druid
    @versions_table = versions_table_component(druid: @druid, cocina_object:)

    render layout: false
  end

  def show_events
    @druid = verified_druid
    @event_types = Rails.cache.fetch('events/event-types', expires_in: 1.hour) { Sdr::Event.types }
    @events_filter_form = if params.key?(EventsFilterForm.model_name.param_key)
                            EventsFilterForm.new(events_filter_params)
                          else
                            EventsFilterForm.with_defaults(available_event_types: @event_types)
                          end
    @events = fetch_events

    render layout: false
  end

  def show_releases
    @druid = verified_druid
    @release_tags = Sdr::Repository.release_tags(druid: @druid, public: false)

    render layout: false
  end

  def show_solr_doc
    @solr_doc_hash = fetch_solr_doc(verified_druid)

    render layout: false
  end

  def show_purl_preview
    @cocina_hash = full_cocina_hash
    constituent_of = SolrDocPresenter.new(solr_doc: fetch_solr_doc(verified_druid)).constituent_of
    @preview = fetch_purl_preview(@cocina_hash, constituent_of)
    render layout: false
  end

  def show_files
    @content = fetch_content
    @druid_token = params[:druid]

    render layout: false
  end

  def show_structure
    @content = fetch_content
    @content_file_sets = @content.content_file_sets.includes(content_files: :content_file_binary).to_a
    @content_type = cocina_hash[:type]
    @content_validation_result = fetch_content_validation_result(content: @content)

    render layout: false
  end

  def show_constituents
    @druid = verified_druid
    @constituents = object_rows(Array(cocina_object.structural.hasMemberOrders.first&.members))

    render layout: false
  end

  def show_structural_csv
    return head :not_found unless Cocina::Models::DRO::TYPES.include?(cocina_hash[:type])

    # The immutable Content reflects the structural of the cocina object.
    send_data StructuralCsv::Export.as_csv(content: fetch_content),
              type: 'text/csv', filename: "#{DruidSupport.bare_druid_from(verified_druid)}_structural.csv"
  end

  def show_descriptive_csv
    # Items, virtual objects and collections only.
    return head :not_found if cocina_object.admin_policy?

    description = DescriptiveCsv::Export.export(source_id: cocina_object.identification.sourceId,
                                                description: cocina_object.description)
    descriptions = { verified_druid => description }
    send_data DescriptiveCsv::Export.as_csv(descriptions:),
              type: 'text/csv', filename: "#{DruidSupport.bare_druid_from(verified_druid)}_description.csv"
  end

  # Records the search_position (used for previous/next navigation between search results) for this
  # druid in the last_search cookie, then redirects to the object's show page.
  def track
    position = Integer(params[:search_position], exception: false)
    remember_search_position(druid_param, position) if position && !turbo_prefetch?

    redirect_to object_path(druid: druid_param), status: :see_other
  end

  # Republishes an object that has previously been published.
  def republish
    druid = druid_param
    @solr_doc = SolrDocPresenter.new(solr_doc: fetch_solr_doc(druid))
    authorize! @solr_doc, to: :update?, with: ObjectPolicy

    unless republishable?
      flash[:danger] = t('show.warnings.republish_failed')
      return redirect_to object_path(druid:)
    end

    Sdr::Repository.publish(druid:, lane_id: 'low')
    toast_and_refresh(t('show.toasts.republish_started'), fallback_location: object_path(druid:))
  end

  def deposit
    cocina_object = Sdr::Repository.find(druid: druid_param)
    authorize! cocina_object, to: :update?, with: ObjectPolicy

    deposit_and_respond(cocina_object:)
  end

  def discard_draft
    cocina_object = Sdr::Repository.find(druid: druid_param)
    authorize! cocina_object, to: :update?, with: ObjectPolicy

    discard_draft_and_redirect(cocina_object:)
  end

  def purge
    cocina_object = Sdr::Repository.find(druid: druid_param)
    authorize! cocina_object, to: :update?, with: ObjectPolicy

    purge_and_redirect(druid: cocina_object.externalIdentifier)
  end

  private

  def deposit_and_respond(cocina_object:) # rubocop:disable Metrics/AbcSize
    Sdr::DepositDraftService.call(cocina_object:, user_name: current_user.sunetid)
    toast_and_refresh(t('show.toasts.deposit_started'), fallback_location: object_path(druid_param))
  rescue Sdr::DepositDraftService::ContentBusyError
    redirect_to object_path(druid_param), flash: { danger: t('show.warnings.content_busy') }
  rescue Sdr::DepositDraftService::NotDepositableError
    redirect_to object_path(druid_param), flash: { danger: t('show.warnings.not_depositable') }
  rescue Sdr::DepositDraftService::UnsavedChangesError
    redirect_to edit_content_path(druid_param), flash: { danger: t('show.warnings.unsaved_content_changes') }
  rescue Sdr::DepositDraftService::InvalidContentError
    # Manage files shows the content errors.
    redirect_to edit_content_path(druid_param, deposit: true)
  rescue Sdr::Repository::Error => e
    Rails.logger.error(e.full_message)
    Honeybadger.notify(e, context: { druid: druid_param })
    redirect_to object_path(druid_param), flash: { danger: t('show.errors.deposit_failed') }
  end

  def discard_draft_and_redirect(cocina_object:) # rubocop:disable Metrics/AbcSize
    druid = cocina_object.externalIdentifier
    Sdr::DiscardDraftService.call(cocina_object:)
    redirect_to object_path(druid), flash: { toast: t('show.toasts.draft_discarded') }
  rescue Sdr::DiscardDraftService::ContentBusyError
    redirect_to object_path(druid), flash: { danger: t('show.warnings.content_busy') }
  rescue Sdr::DiscardDraftService::NotDiscardableError
    redirect_to object_path(druid), flash: { danger: t('show.warnings.not_discardable') }
  rescue Sdr::Repository::Error => e
    Rails.logger.error(e.full_message)
    Honeybadger.notify(e, context: { druid: })
    redirect_to object_path(druid), flash: { danger: t('show.errors.discard_failed') }
  end

  def purge_and_redirect(druid:) # rubocop:disable Metrics/AbcSize
    Sdr::PurgeService.purge(druid:, user_name: current_user.sunetid)
    # A purged object no longer has an object page.
    redirect_to root_path, flash: { toast: t('show.toasts.purged') }
  rescue Sdr::PurgeService::CannotPurgeError
    redirect_to object_path(druid), flash: { danger: t('show.warnings.cannot_purge') }
  rescue Sdr::PurgeService::ContentBusyError
    redirect_to object_path(druid), flash: { danger: t('show.warnings.content_busy') }
  rescue Sdr::PurgeService::Error => e
    Rails.logger.error(e.full_message)
    Honeybadger.notify(e, context: { druid: })
    redirect_to object_path(druid), flash: { danger: t('show.errors.purge_failed') }
  end

  def events_filter_params
    EventsFilterForm.params_from(params)
  end

  def fetch_events
    return [] unless @events_filter_form.event_types_selected?

    Sdr::Event.list(druid: @druid,
                    event_types: @events_filter_form.event_types_filter(available_event_types: @event_types),
                    from: @events_filter_form.from_time, to: @events_filter_form.to_time)
  end

  def unsaved_content_changes?(druid)
    return false unless CocinaSupport.object_type_with_content?(@cocina_object)

    content = Content.mutable_for(@cocina_object)
    return false unless content

    full_cocina_object = CocinaSupport.build_from_cocina_hash(fetch_full_cocina_hash(druid).dup)
    Contents::UnsavedChanges.call(content:, cocina_object: full_cocina_object)
  end

  def republishable?
    return false unless @solr_doc.publishable_type?

    Sdr::WorkflowService.published?(druid: @solr_doc.druid)
  end

  # Determines the previous/next druids within the current search results, based on the
  # "search_position" (1-based position within the search result set) recorded for this druid in
  # the last_search cookie by #track.
  def set_search_navigation
    position = search_position(druid_param)
    total_results = Integer(@total_results, exception: false)
    return if @last_search_form.blank? || position.nil? || total_results.nil?
    return unless position.positive?

    navigation = Searchers::ItemNavigation.call(druid: druid_param, search_form: @last_search_form, position:,
                                                user_scope: current_user_scope)
    return if navigation.blank?

    @search_position = position
    @navigation = navigation
  end

  def search_position(druid)
    last_search = cookies.signed[:last_search]
    return nil if last_search.blank? || last_search['search_position_druid'] != druid

    Integer(last_search['search_position'], exception: false)
  end

  def remember_search_position(druid, position)
    last_search = cookies.signed[:last_search] || {}
    cookies.signed[:last_search] =
      { value: last_search.merge('search_position' => position, 'search_position_druid' => druid) }
  end

  def track_recent_object(druid)
    other_recent_druids = Array(session[:recent_object_druids]).excluding(druid)
    session[:recent_object_druids] = [druid, *other_recent_druids].first(RECENT_OBJECTS_LIMIT)
  end

  def turbo_prefetch?
    request.headers['X-Sec-Purpose'] == 'prefetch'
  end

  def verified_druid
    @verified_druid ||= verify_token(params[:druid])
  end

  # Note that this is a "live" solr document built from latest DSA data.
  def fetch_solr_doc(druid)
    Rails.cache.fetch(CacheSupport.solr_doc_cache_key(druid:), expires_in: solr_doc_cache_expires_in) do
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
    cache_key = CacheSupport.solr_doc_cache_key(druid:)
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

  # The full cocina hash is fresh if its lock matches the cocina hash's (which #show keeps fresh).
  def fetch_full_cocina_hash(druid)
    lock = fetch_cocina_hash(druid)[:lock]
    cache_key = full_cocina_hash_cache_key(druid)
    cached = Rails.cache.read(cache_key)
    return cached[:value] if cached && cached[:lock] == lock

    value = compute_cocina_hash(druid, without_structural_contains: false)
    Rails.cache.write(cache_key, { lock: value[:lock], value: }, expires_in: 1.hour)
    value
  end

  def compute_cocina_hash(druid, without_structural_contains: true)
    cocina_object = Sdr::Repository.find(druid:, without_structural_contains:)
    CocinaDisplay::Utils.deep_compact_blank(cocina_object.to_h, preserve_keys: [:label])
  end

  def cocina_hash_cache_key(druid)
    "objects/cocina-hash-without-contains/#{druid}"
  end

  def full_cocina_hash_cache_key(druid)
    "objects/cocina-hash/#{druid}"
  end

  def solr_doc_cache_expires_in
    (Settings.reload_intervals.cocina_model / 1000.0).seconds - 1.second
  end

  # Keyed by constituent_of too, since virtual object membership can change without changing the lock.
  def fetch_purl_preview(cocina_hash, constituent_of)
    cache_key = ['objects/purl-preview', cocina_hash[:externalIdentifier], cocina_hash[:lock],
                 Digest::SHA256.hexdigest(constituent_of.to_json)].join('/')
    body = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      PurlPreviewService.call(cocina_hash:, constituent_of:)
    end
    Nokogiri::HTML(body).css('main').inner_html.html_safe # rubocop:disable Rails/OutputSafety
  rescue PurlPreviewService::Error => e
    Honeybadger.notify(e, context: { cocina_hash: })
    nil
  end

  def cocina_hash
    @cocina_hash ||= fetch_cocina_hash(verified_druid)
  end

  def full_cocina_hash
    @full_cocina_hash ||= fetch_full_cocina_hash(verified_druid)
  end

  # Without the file sets (structural.contains).
  def cocina_object
    # dup since build_from_cocina_hash deletes keys from the hash it is given.
    @cocina_object ||= CocinaSupport.build_from_cocina_hash(cocina_hash.dup)
  end

  # The immutable Content usually exists for the lock, so the full cocina object is only fetched when it doesn't.
  def fetch_content
    Content.find_by(druid: verified_druid, lock: cocina_hash[:lock], immutable: true) ||
      Contents::Builder.find_or_create(cocina_object: CocinaSupport.build_from_cocina_hash(full_cocina_hash.dup))
  end

  # The immutable Content is fixed for a lock, so its validation result for a content type is too.
  def fetch_content_validation_result(content:)
    cache_key = "objects/content-validation/#{content.druid}/#{content.lock}/#{cocina_hash[:type]}"
    result_hash = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      Contents::Validator.call(content:, cocina_object:).to_h
    end
    Contents::Validators::Result.new(**result_hash)
  end

  # Looks up titles/permissions of given druids without filtering by view permission, so that an object
  # can be shown for every constituent object even when the user is not permitted to link to some of them.
  # @param druids [Array] the list of druids to look up
  # @return [Array<Array(String, String, Boolean)>] [title, druid, viewable] tuples, in the given order
  def object_rows(druids)
    fields = [Search::Fields::ID, Search::Fields::TITLE, Search::Fields::COLLECTION_DRUIDS, Search::Fields::APO_DRUID]
    docs_by_druid = Searchers::ItemByDruid.call(druids:, user_scope: nil, fields:).index_by(&:druid)
    druids.filter_map do |druid|
      doc = docs_by_druid[druid]
      next unless doc

      [doc.title, doc.druid, allowed_to?(:show?, doc, with: ObjectPolicy)]
    end
  end

  def druid_param
    DruidSupport.prefixed_druid_from(params.expect(:druid)).tap do |druid|
      raise ActionController::RoutingError, 'Not Found' unless DruidValidator::PATTERN.match?(druid)
    end
  end
end
