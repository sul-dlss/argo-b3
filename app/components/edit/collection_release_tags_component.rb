# frozen_string_literal: true

module Edit
  # Component for rendering the release tags of a collection: per target, whether to release it and what to include.
  # The form's object must be a CollectionReleaseTagsForm (released? and release_what per target prefix).
  class CollectionReleaseTagsComponent < ApplicationComponent
    def initialize(form:)
      @form = form
      super()
    end

    attr_reader :form

    def target_prefixes
      CollectionReleaseTagsForm::TARGET_PREFIXES.values
    end
  end
end
