# frozen_string_literal: true

module Edit
  # Component for rendering edit form for release tags
  # The form's object must provide searchworks_target, earthworks_target, and purl_sitemap_target.
  class ReleaseTagsComponent < ApplicationComponent
    ITEM_OPTIONS = [
      ['Follow collection settings', ReleaseTagsForm::RELEASE_TO_COLLECTION],
      ['Release', ReleaseTagsForm::RELEASE_TO_TARGETS],
      ['Do not release', ReleaseTagsForm::NO_RELEASE]
    ].freeze

    COLLECTION_OPTIONS = [
      ['Do not release', CollectionReleaseTagsForm::NO_RELEASE],
      ['Release collection', CollectionReleaseTagsForm::RELEASE_COLLECTION],
      ['Release collection and member items', CollectionReleaseTagsForm::RELEASE_COLLECTION_AND_MEMBERS]
    ].freeze

    # @param form [ActionView::Helpers::FormBuilder] the form for a ReleaseTagsForm or CollectionReleaseTagsForm
    # @param options [Array<Array(String, String)>] the [label, value] choices for each release target
    def initialize(form:, options: ITEM_OPTIONS)
      @form = form
      @options = options
      super()
    end

    attr_reader :form, :options
  end
end
