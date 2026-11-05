# frozen_string_literal: true

module Show
  # Component for rendering the tags box on the show page.
  class TagComponent < ApplicationComponent
    include FacetedTagLinkConcern

    # @param solr_doc [SolrDocPresenter] the object, used to decide whether the user can manage its tags
    def initialize(solr_doc:, tags:, pinned_tags:)
      @solr_doc = solr_doc
      @tags = tags
      @pinned_tags = pinned_tags
      super()
    end

    attr_reader :solr_doc, :tags, :pinned_tags

    def pinned?(tag)
      pinned_tags.include?(tag)
    end

    def tag?
      helpers.allowed_to?(:tag?, solr_doc, with: ObjectPolicy)
    end
  end
end
