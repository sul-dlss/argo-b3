# frozen_string_literal: true

# Controller for looking up the object defaults of an APO, e.g., for applying them to the rights tab
# of the item form when an APO is selected.
# Each default is returned as { value:, text: }, where value is nil when the APO has no default and
# text is the help text describing the default.
class ApoDefaultsController < ApplicationController
  # The APOs in the item form are restricted to those the user can register with (Searchers::AdminPolicyList),
  # so any authenticated user may look up the defaults of an APO.
  skip_verify_authorized

  def show
    apo = find_apo
    # The item form requests this with fetch, so respond with a status rather than redirecting and showing a flash.
    return head :not_found if apo.nil?

    render json: ApoDefaultsPresenter.new(apo:).to_h
  end

  private

  # @return [CocinaModels::AdminPolicy, nil] nil if there is no APO for the druid
  def find_apo
    cocina_object = Sdr::Repository.find(druid: DruidSupport.prefixed_druid_from(params.expect(:druid)))
    CocinaModels::AdminPolicy.build_from_cocina_object(cocina_object) if cocina_object.admin_policy?
  rescue Sdr::Repository::NotFoundResponse
    nil
  end
end
