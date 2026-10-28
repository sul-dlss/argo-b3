# frozen_string_literal: true

module Dashboard
  # Render the table of the Items most recently updated by the user on the dashboard.
  class RecentDraftsAndDepositsTableComponent < ApplicationComponent
    # @param object_docs [Array<SolrDocPresenter>] the Items, most recently updated first
    # @param statuses [Hash<String, Symbol>] the ObjectStatusPresenter#status of each Item, keyed by druid
    # @param search_form [ResultsSearchForm] the search for the complete list of Items
    def initialize(object_docs:, statuses:, search_form:)
      @object_docs = object_docs
      @statuses = statuses
      @search_form = search_form
      super()
    end

    attr_reader :object_docs

    def label
      'Recent drafts and deposits'
    end

    def render?
      object_docs.any?
    end

    def title_link(object_doc)
      helpers.link_to_object(object_doc.title, object_doc.druid)
    end

    def collection_link_values(object_doc)
      Array(object_doc.collection_druids).map.with_index do |collection_druid, index|
        helpers.link_to_object(object_doc.collection_titles[index], collection_druid)
      end
    end

    def status_label(object_doc)
      render(Show::StatusLabelComponent.new(status: @statuses.fetch(object_doc.druid)))
    end

    def last_updated_date(object_doc)
      helpers.format_datetime(Time.zone.parse(object_doc.last_updated_date))
    end

    def search_path
      search_items_path(@search_form.attributes)
    end
  end
end
