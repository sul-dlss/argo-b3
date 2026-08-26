# frozen_string_literal: true

module Dashboard
  # Render the table of a user's pinned collections on the dashboard.
  class PinnedCollectionsTableComponent < ApplicationComponent
    # @param pinned_collection_docs [Array] the pinned collection search result docs
    def initialize(pinned_collection_docs:, classes: [])
      @pinned_collection_docs = pinned_collection_docs
      @classes = classes
      super()
    end

    attr_reader :pinned_collection_docs

    def label
      'Pinned collections'
    end

    def title_link(item_doc)
      helpers.link_to_object(item_doc.title, item_doc.druid)
    end

    def apo_link(item_doc)
      helpers.link_to_object(item_doc.apo_title, item_doc.apo_druid)
    end

    def classes
      merge_classes('object-type-collection', @classes)
    end
  end
end
