# frozen_string_literal: true

# Controller for objects (DRO, collection, admin policy)
class ObjectsController < ApplicationController
  skip_verify_authorized only: %i[show_json show_workflows show_details show_header show_versions show_purl_preview]

  include TokenConcern

  # The strategy is to authorize on show, but not repeat authorization on other show endpoints.
  # This avoids having to make additional calls that would be required for the authorization, but not the showing.
  # For the other show endpoints, the druid is signed and verified to ensure that the druid is valid and was generated
  # by the show action.
  # Thus, the signing / verification acts as authorization for those endpoints.
  self.token_purpose = 'show'

  def show
    @solr_doc = SolrDocPresenter.new(solr_doc: fetch_solr_doc(params[:druid]))
    authorize! @solr_doc, with: ObjectPolicy

    set_from_last_search_cookie # This provides @last_search_form
    @druid_token = generate_token(params[:druid])
  end

  def show_header
    @solr_doc = SolrDocPresenter.new(solr_doc: fetch_solr_doc(verified_druid))

    render layout: false
  end

  def show_details
    # Need to find way to avoid retrieving solr doc again.
    @solr_doc = SolrDocPresenter.new(solr_doc: fetch_solr_doc(verified_druid))

    case @solr_doc.object_type
    when 'collection'
      render :show_collection_details, layout: false
    when 'admin_policy'
      render :show_admin_policy_details, layout: false
    else
      # This also includes agreements and virtual objects.
      render :show_dro_details, layout: false
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

  def show_purl_preview
    @cocina_hash = fetch_cocina_hash(verified_druid)
    @preview = fetch_purl_preview(@cocina_hash)
    render layout: false
  end

  private

  def verified_druid
    @verified_druid ||= verify_token(params[:druid])
  end

  def fetch_solr_doc(druid)
    Rails.cache.fetch("objects/solr-doc/#{druid}", expires_in: 10.seconds) do
      Sdr::Repository.find_solr(druid:)
    end
  end

  def fetch_cocina_hash(druid)
    cache_key = "objects/cocina-hash/#{druid}"
    Rails.cache.fetch(cache_key, expires_in: 10.seconds) do
      cocina_object = Sdr::Repository.find(druid:)
      CocinaDisplay::Utils.deep_compact_blank(cocina_object.to_h)
    end
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
end
