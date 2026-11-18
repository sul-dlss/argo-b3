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

    # @param form [ActionView::Helpers::FormBuilder] the form for a ReleaseTagsForm or ItemReleaseTagsForm
    # @param follow_collection_disabled_fields [Array<Symbol>] target fields whose follow collection choice is disabled
    def initialize(form:, follow_collection_disabled_fields: [])
      @form = form
      @follow_collection_disabled_fields = follow_collection_disabled_fields
      super()
    end

    attr_reader :form

    def options_for(field_name)
      return ITEM_OPTIONS unless @follow_collection_disabled_fields.include?(field_name)

      ITEM_OPTIONS.map do |label, value|
        value == ReleaseTagsForm::RELEASE_TO_COLLECTION ? [label, value, { disabled: true }] : [label, value]
      end
    end
  end
end
