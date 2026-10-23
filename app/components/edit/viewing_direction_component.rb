# frozen_string_literal: true

module Edit
  # Component for rendering edit form for viewing direction
  # The form's object must include CocinaModels::ContentTypeConcern.
  class ViewingDirectionComponent < ApplicationComponent
    def initialize(form:, **select_options)
      @form = form
      @select_options = select_options
      super()
    end

    attr_reader :form, :select_options
  end
end
