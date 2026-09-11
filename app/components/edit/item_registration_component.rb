# frozen_string_literal: true

module Edit
  # Component for rendering the per-item fields (source ID, barcode, title, catalog record ID)
  # when registering multiple items.
  class ItemRegistrationComponent < ApplicationComponent
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form
  end
end
