# frozen_string_literal: true

module Dashboard
  # Render the table of a user's pinned APOs on the dashboard.
  class PinnedAposTableComponent < ApplicationComponent
    # @param pinned_apo_docs [Array] the pinned APO search result docs
    def initialize(pinned_apo_docs:, classes: [])
      @pinned_apo_docs = pinned_apo_docs
      @classes = classes
      super()
    end

    attr_reader :pinned_apo_docs

    def label
      'Pinned APOs'
    end

    def title_link(apo_doc)
      helpers.link_to_object(apo_doc.title, apo_doc.druid)
    end

    def agreement_link(apo_doc)
      return if apo_doc.agreement_druid.blank?

      helpers.link_to_object(apo_doc.agreement_title, apo_doc.agreement_druid)
    end

    def classes
      merge_classes('object-type-apo', @classes)
    end
  end
end
