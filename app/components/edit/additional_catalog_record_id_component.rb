# frozen_string_literal: true

module Edit
  # Component for rendering edit form for an additional FOLIO Instance HRID
  class AdditionalCatalogRecordIdComponent < ApplicationComponent
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form
  end
end
