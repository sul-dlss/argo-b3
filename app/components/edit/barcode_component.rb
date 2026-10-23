# frozen_string_literal: true

module Edit
  # Component for rendering edit form for barcode
  # The form's object must include CocinaModels::BarcodeConcern.
  class BarcodeComponent < ApplicationComponent
    def initialize(form:, container_classes: 'my-field', label_classes: [])
      @form = form
      @container_classes = container_classes
      @label_classes = label_classes
      super()
    end

    attr_reader :form, :label_classes, :container_classes
  end
end
