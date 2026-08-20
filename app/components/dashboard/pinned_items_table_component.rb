# frozen_string_literal: true

module Dashboard
  # Render the table of a user's pinned items on the dashboard.
  class PinnedItemsTableComponent < ApplicationComponent
    # @param pinned_item_docs [Array] the pinned item search result docs
    def initialize(pinned_item_docs:, classes: [])
      @pinned_item_docs = pinned_item_docs
      @classes = classes
      super()
    end

    attr_reader :pinned_item_docs

    def label
      'Pinned items'
    end

    def title_link(item_doc)
      helpers.link_to(item_doc.title, object_path(druid: item_doc.druid))
    end

    def apo_link(item_doc)
      helpers.link_to(item_doc.apo_title, object_path(druid: item_doc.apo_druid))
    end

    def collection_link_values(item_doc)
      Array(item_doc.collection_druids).map.with_index do |collection_druid, index|
        helpers.link_to(item_doc.collection_titles[index], object_path(druid: collection_druid))
      end
    end

    def classes
      merge_classes('object-type-item', @classes)
    end
  end
end
