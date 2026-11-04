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

    # @param form [ActionView::Helpers::FormBuilder] the form for a ReleaseTagsForm, ItemReleaseTagsForm, or
    #   CollectionReleaseTagsForm
    # @param options [Array<Array(String, String)>] the [label, value] choices for each release target
    # @param follow_collection_disabled_fields [Array<Symbol>] target fields whose follow collection choice is disabled
    def initialize(form:, options: ITEM_OPTIONS, follow_collection_disabled_fields: [])
      @form = form
      @options = options
      @follow_collection_disabled_fields = follow_collection_disabled_fields
      super()
    end

    attr_reader :form

    def options_for(field_name)
      return @options unless @follow_collection_disabled_fields.include?(field_name)

      @options.map do |label, value|
        value == ReleaseTagsForm::RELEASE_TO_COLLECTION ? [label, value, { disabled: true }] : [label, value]
      end
    end
  end
end
