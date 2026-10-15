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

    render json: rights_defaults(apo).merge(access_defaults(apo))
  end

  private

  # @return [CocinaModels::AdminPolicy, nil] nil if there is no APO for the druid
  def find_apo
    cocina_object = Sdr::Repository.find(druid: DruidSupport.prefixed_druid_from(params.expect(:druid)))
    CocinaModels::AdminPolicy.build_from_cocina_object(cocina_object) if cocina_object.admin_policy?
  rescue Sdr::Repository::NotFoundResponse
    nil
  end

  # @param apo [CocinaModels::AdminPolicy]
  def rights_defaults(apo)
    {
      use_and_reproduction_statement: default_for(apo.use_and_reproduction_statement),
      copyright: default_for(apo.copyright),
      license: default_for(apo.license) { |license| license_label(license) }
    }
  end

  # @param apo [CocinaModels::AdminPolicy]
  def access_defaults(apo)
    {
      view: default_for(apo.access_view) { |view| AccessRightsSupport.view_or_download_label(view) },
      download: default_for(apo.access_download) { |download| AccessRightsSupport.view_or_download_label(download) },
      location: default_for(apo.access_location) { |location| AccessRightsSupport.location_label(location) }
    }
  end

  # @param value [String, nil] the APO's default
  # @yield [value] optionally maps the value to the label shown in the help text
  def default_for(value)
    value = value.presence
    label = if value.nil?
              t('edit.items.fields.apo_default.none')
            else
              block_given? ? yield(value) : value
            end
    { value:, text: t('edit.items.fields.apo_default.text', value: label) }
  end

  # @return [String] the label of the license option for the URI, or the URI if it is not an option
  def license_label(uri)
    Constants::LICENSE_OPTIONS.find { |option| option[:uri] == uri }&.fetch(:label) || uri
  end
end
