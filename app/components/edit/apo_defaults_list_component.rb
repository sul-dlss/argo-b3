# frozen_string_literal: true

module Edit
  # Component for listing, read-only, the APO defaults that will be applied to an object, in the "APO default = …"
  # wording of the rights fields in Edit item.
  class ApoDefaultsListComponent < ApplicationComponent
    # @param apo_defaults [ApoDefaultsPresenter]
    # @param access [Boolean] true to list the view, download, and location access defaults (items only)
    def initialize(apo_defaults:, access:)
      @apo_defaults = apo_defaults
      @access = access
      super()
    end

    def call
      render Elements::DescriptionListComponent.new(hash: defaults_by_label)
    end

    private

    # Labelled as the fields are in Edit item.
    def defaults_by_label
      texts = @apo_defaults.to_h.transform_values { |default| default[:text] }
      access_texts = { 'View access' => texts[:view], 'Download access' => texts[:download],
                       'Location' => texts[:location] }
      rights_texts = {
        t('edit.items.fields.use_and_reproduction_statement.label') => texts[:use_and_reproduction_statement],
        t('edit.items.fields.copyright.label') => texts[:copyright],
        t('edit.items.fields.license.label') => texts[:license]
      }
      @access ? access_texts.merge(rights_texts) : rights_texts
    end
  end
end
