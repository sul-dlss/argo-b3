# frozen_string_literal: true

module Show
  # Component for the object show page's heading: the object type badge, the title, the pin button, and, optionally,
  # a read-only badge.
  class HeadingComponent < ApplicationComponent
    # @param solr_doc [SolrDocPresenter] the object
    # @param pinned [Boolean] whether the user has pinned the object
    # @param read_only_badge [Boolean] whether to show the "Read only" badge
    def initialize(solr_doc:, pinned:, read_only_badge:)
      @solr_doc = solr_doc
      @pinned = pinned
      @read_only_badge = read_only_badge
      super()
    end

    attr_reader :solr_doc, :pinned

    def read_only_badge?
      @read_only_badge
    end
  end
end
