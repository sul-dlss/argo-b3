# frozen_string_literal: true

module Dashboard
  # Render the table of a user's pinned tags on the dashboard.
  class PinnedTagsTableComponent < ApplicationComponent
    # @param pinned_tags [Array] the pinned tags
    def initialize(pinned_tags:, classes: [])
      @pinned_tags = pinned_tags
      @classes = classes
      super()
    end

    attr_reader :pinned_tags

    def label
      'Pinned tags'
    end

    def tag_link(pinned_tag)
      helpers.link_to(pinned_tag.tag, search_path(tags: [pinned_tag.tag]))
    end

    def classes
      merge_classes('object-type-tag', @classes)
    end
  end
end
