# frozen_string_literal: true

module Show
  # Component for the object page's Refresh from FOLIO button (items and collections), enabled when the user can
  # edit the object, it is Registered, Draft, or Deposited, and it has a FOLIO Instance HRID marked Refresh on deposit.
  class FolioRefreshButtonComponent < ApplicationComponent
    ENABLED_STATUSES = %i[registered draft deposited].freeze

    # @param classes [String] classes for the button (e.g., its spacing in Elements::ButtonListComponent)
    def initialize(solr_doc:, cocina_object:, object_status_presenter:, classes: [])
      @solr_doc = solr_doc
      @cocina_object = cocina_object
      @object_status_presenter = object_status_presenter
      @classes = classes
      super()
    end

    def call
      render SdrViewComponents::Elements::ButtonFormComponent.new(
        link: new_object_folio_refresh_path(@solr_doc.druid), label: 'Refresh from FOLIO', variant: 'outline-primary',
        disabled: !enabled?, classes: @classes
      )
    end

    private

    # Disabled without a refreshable FOLIO Instance HRID, and while
    # Staging, Assembling, Depositing, or In Error and without permissions.
    def enabled?
      helpers.allowed_to?(:update?, @solr_doc, with: ObjectPolicy) &&
        CocinaSupport.folio_refresh_catalog_record_id(@cocina_object).present? &&
        @object_status_presenter.status.in?(ENABLED_STATUSES)
    end
  end
end
