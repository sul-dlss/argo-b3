# frozen_string_literal: true

module Edit
  # Component for rendering edit form for serials (part label and sort key of the Folio catalog link)
  class SerialsComponent < ApplicationComponent
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form
  end
end
