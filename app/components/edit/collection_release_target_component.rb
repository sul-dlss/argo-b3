# frozen_string_literal: true

module Edit
  # Component for one release target of a collection: whether to release to it and what to include.
  # The form's object must be a CollectionReleaseTagsForm (released? and release_what per target prefix).
  class CollectionReleaseTargetComponent < ApplicationComponent
    # @param form [ActionView::Helpers::FormBuilder] the form for a CollectionReleaseTagsForm
    # @param prefix [Symbol] a field prefix from CollectionReleaseTagsForm::TARGET_PREFIXES
    def initialize(form:, prefix:)
      @form = form
      @prefix = prefix
      super()
    end

    attr_reader :form, :prefix

    def target_label
      t("release_tags.#{prefix}")
    end

    def released?
      form.object.released?(prefix)
    end

    def checked?(value)
      released? && form.object.release_what(prefix) == value
    end
  end
end
