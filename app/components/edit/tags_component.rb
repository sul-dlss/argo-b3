# frozen_string_literal: true

module Edit
  # Component for rendering edit forms for the tags of an item (other, project, and ticket tags)
  class TagsComponent < ApplicationComponent
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form
  end
end
