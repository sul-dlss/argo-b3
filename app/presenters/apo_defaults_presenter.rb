# frozen_string_literal: true

# Presenter for the object defaults of an APO, each as { value:, text: }, where value is nil when the APO has no
# default and text is the help text describing the default (e.g., "APO default = World").
class ApoDefaultsPresenter
  # @param apo [CocinaModels::AdminPolicy]
  def initialize(apo:)
    @apo = apo
  end

  # @return [Hash{Symbol => Hash}] the rights defaults, then the access defaults
  def to_h
    rights_defaults.merge(access_defaults)
  end

  def rights_defaults
    {
      use_and_reproduction_statement: default_for(apo.use_and_reproduction_statement),
      copyright: default_for(apo.copyright),
      license: default_for(apo.license) { |license| license_label(license) }
    }
  end

  def access_defaults
    {
      view: default_for(apo.access_view) { |view| AccessRightsSupport.view_or_download_label(view) },
      download: default_for(apo.access_download) { |download| AccessRightsSupport.view_or_download_label(download) },
      location: default_for(apo.access_location) { |location| AccessRightsSupport.location_label(location) }
    }
  end

  private

  attr_reader :apo

  # @param value [String, nil] the APO's default
  # @yield [value] optionally maps the value to the label shown in the help text
  def default_for(value)
    value = value.presence
    label = if value.nil?
              I18n.t('edit.items.fields.apo_default.none')
            else
              block_given? ? yield(value) : value
            end
    { value:, text: I18n.t('edit.items.fields.apo_default.text', value: label) }
  end

  # @return [String] the label of the license option for the URI, or the URI if it is not an option
  def license_label(uri)
    Constants::LICENSE_OPTIONS.find { |option| option[:uri] == uri }&.fetch(:label) || uri
  end
end
