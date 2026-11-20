# frozen_string_literal: true

module Show
  # Component for the object page's Apply APO defaults button (items and collections), enabled when the user can
  # edit the object and it is Registered, Draft, or Deposited.
  class ApplyApoDefaultsButtonComponent < ApplicationComponent
    ENABLED_STATUSES = %i[registered draft deposited].freeze

    # @param classes [String] classes for the button (e.g., its spacing in Elements::ButtonListComponent)
    def initialize(solr_doc:, object_status_presenter:, classes: [])
      @solr_doc = solr_doc
      @object_status_presenter = object_status_presenter
      @classes = classes
      super()
    end

    def call
      render SdrViewComponents::Elements::ButtonFormComponent.new(
        link: new_object_apo_defaults_path(@solr_doc.druid), label: 'Apply APO defaults', variant: 'outline-primary',
        disabled: !enabled?, classes: @classes
      )
    end

    private

    # Design standard deviation: AVAIL-4. Per #1441, disabled while Staging, Assembling, Depositing, or In Error
    # with no reason shown. Permission is checked first, so that read-only users don't trigger the status's DSA
    # requests.
    def enabled?
      helpers.allowed_to?(:update?, @solr_doc, with: ObjectPolicy) &&
        @object_status_presenter.status.in?(ENABLED_STATUSES)
    end
  end
end
