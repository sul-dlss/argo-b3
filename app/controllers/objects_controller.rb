# frozen_string_literal: true

# Controller for objects (DRO, collection, admin policy)
class ObjectsController < ApplicationController
  skip_verify_authorized only: %i[show_json show_workflows show_details show_header]

  def show
    @solr_doc = SolrDocPresenter.new(solr_doc: fetch_solr_doc(params[:druid]))
    authorize! @solr_doc, with: ObjectPolicy

    set_from_last_search_cookie # This provides @last_search_form
    @druid_token = generate_token(params[:druid])
  end

  def show_header
    @solr_doc = SolrDocPresenter.new(solr_doc: fetch_solr_doc(verify_token(params[:druid])))

    render layout: false
  end

  def show_details
    # Need to find way to avoid retrieving solr doc again.
    @solr_doc = SolrDocPresenter.new(solr_doc: fetch_solr_doc(verify_token(params[:druid])))

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
    # return render plain: 'Internal Server Error', status: :internal_server_error
    @cocina_object = Sdr::Repository.find(druid: verify_token(params[:druid]))

    render layout: false
  end

  def show_workflows
    @druid = verify_token(params[:druid])
    @workflows = Sdr::WorkflowService.workflows_for(druid: @druid)

    render layout: false
  end

  private

  # The strategy is to authorize on show, but not repeat authorization on other show endpoints.
  # This avoids having to make additional calls that would be required for the authorization, but not the showing.
  # For the other show endpoints, the druid is signed and verified to ensure that the druid is valid and was generated
  # by the show action.
  # Thus, the signing / verification acts as authorization for those endpoints.
  def verifier
    Rails.application.message_verifier(:argo)
  end

  # @return [String] a token that can be used to verify the druid
  def generate_token(druid)
    # Using fixed expires at keeps the token constant for a given druid to avoid interfering with morphing.
    verifier.generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
  end

  # @return [String] the druid if the token is valid, otherwise raises an error
  # @raise [ActiveSupport::MessageVerifier::InvalidSignature] if the token is invalid
  def verify_token(token)
    verifier.verify(token, purpose: 'show')
  end

  def fetch_solr_doc(druid)
    Rails.cache.fetch("objects/solr-doc/#{druid}", expires_in: 10.seconds) do
      Sdr::Repository.find_solr(druid:)
    end
  end
end
