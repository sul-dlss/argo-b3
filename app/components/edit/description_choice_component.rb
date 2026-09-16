# frozen_string_literal: true

module Edit
  # Component for rendering edit form for description choice
  class DescriptionChoiceComponent < ApplicationComponent
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form
  end
end
