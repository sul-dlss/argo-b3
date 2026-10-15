# frozen_string_literal: true

module Edit
  # Component for rendering edit form for release tags
  class ReleaseTagsComponent < ApplicationComponent
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form

    def options
      [
        ['Follow collection settings', ReleaseTagsForm::RELEASE_TO_COLLECTION],
        ['Release', ReleaseTagsForm::RELEASE_TO_TARGETS],
        ['Do not release', ReleaseTagsForm::NO_RELEASE]
      ]
    end
  end
end
