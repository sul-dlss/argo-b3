# frozen_string_literal: true

module Dashboard
  # Render the object show pages most recently visited by the user.
  class RecentObjectsTableComponent < ApplicationComponent
    def initialize(recent_object_docs:)
      @recent_object_docs = recent_object_docs
      super()
    end

    attr_reader :recent_object_docs

    def label
      'Recent objects'
    end

    def title_link(object_doc)
      helpers.link_to_object(object_doc.title, object_doc.druid)
    end

    def object_type_label(object_doc)
      SolrDocPresenter::OBJECT_TYPES.fetch(object_doc.object_type).fetch(:label)
    end
  end
end
