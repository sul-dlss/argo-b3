# frozen_string_literal: true

module Show
  # Component for the item page's Extract text button, enabled when the user can extract text from the item now.
  class ExtractTextButtonComponent < ApplicationComponent
    # @param content_type [String] the cocina type URI of the item
    # @param classes [String] classes for the button (e.g., its spacing in Elements::ButtonListComponent)
    def initialize(solr_doc:, object_status_presenter:, content_type:, classes: [])
      @solr_doc = solr_doc
      @object_status_presenter = object_status_presenter
      @content_type = content_type
      @classes = classes
      super()
    end

    def call
      render SdrViewComponents::Elements::ButtonFormComponent.new(
        link: new_item_text_extraction_path(@solr_doc.druid), label: 'Extract text', variant: 'outline-primary',
        disabled: !enabled?, classes: @classes
      )
    end

    private

    # Design standard deviation: AVAIL-3, AVAIL-4. Per #1440, disabled (not hidden) for other content types, with
    # no reason shown. Permission is checked first, so that read-only users don't trigger the status's DSA requests.
    def enabled?
      helpers.allowed_to?(:update?, @solr_doc, with: ObjectPolicy) &&
        Sdr::TextExtraction.workflow_name_for(@content_type).present? &&
        @object_status_presenter.status.in?(%i[deposited draft])
    end
  end
end
