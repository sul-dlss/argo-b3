# frozen_string_literal: true

module Dashboard
  # Render the table of a user's pinned virtual objects on the dashboard.
  class PinnedVirtualObjectsTableComponent < ApplicationComponent
    # @param pinned_virtual_object_docs [Array] the pinned virtual object search result docs
    def initialize(pinned_virtual_object_docs:, classes: [])
      @pinned_virtual_object_docs = pinned_virtual_object_docs
      @classes = classes
      super()
    end

    attr_reader :pinned_virtual_object_docs

    def label
      'Pinned virtual objects'
    end

    def title_link(virtual_object_doc)
      helpers.link_to_object(virtual_object_doc.title, virtual_object_doc.druid)
    end

    def apo_link(virtual_object_doc)
      helpers.link_to_object(virtual_object_doc.apo_title, virtual_object_doc.apo_druid)
    end

    def collection_link_values(virtual_object_doc)
      Array(virtual_object_doc.collection_druids).map.with_index do |collection_druid, index|
        helpers.link_to_object(virtual_object_doc.collection_titles[index], collection_druid)
      end
    end

    def classes
      merge_classes('object-type-virtual-object', @classes)
    end
  end
end
