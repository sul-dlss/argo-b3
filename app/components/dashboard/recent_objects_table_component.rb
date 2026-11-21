# frozen_string_literal: true

module Dashboard
  # Render the object show pages most recently visited by the user.
  class RecentObjectsTableComponent < ApplicationComponent
    VISIBLE_TAGS_LIMIT = 3

    def initialize(recent_object_docs:)
      @recent_object_docs = recent_object_docs.map { |object_doc| SolrDocPresenter.new(solr_doc: object_doc.solr_doc) }
      super()
    end

    attr_reader :recent_object_docs

    def label
      t('dashboard.recent_objects.label')
    end

    def title_link(object_doc)
      helpers.link_to_object(object_doc.title, object_doc.druid)
    end

    # The first few tags, followed by a count of the rest, so many tags don't make the row tall.
    def tag_values(object_doc)
      tags = Array(object_doc.all_tags)
      return tags if tags.size <= VISIBLE_TAGS_LIMIT

      more_tags = t('dashboard.recent_objects.more_tags', count: tags.size - VISIBLE_TAGS_LIMIT)
      tags.first(VISIBLE_TAGS_LIMIT) + [tag.span(more_tags, class: 'fst-italic')]
    end
  end
end
