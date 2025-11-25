# frozen_string_literal: true

module Search
  # Component to render a single item result in search results
  class ItemResultComponent < ViewComponent::Base
    with_collection_parameter :result

    # @param result [SearchResults::Item]
    def initialize(result:)
      @result = result
      super()
    end

    attr_reader :result

    delegate :title, :druid, :bare_druid, :index, to: :result

    def id
      "item-result-#{bare_druid}"
    end

    def content_type_values
      [result.content_types.join(', ')]
    end

    def admin_policy_values
      [helpers.link_to_item(result.apo_title, result.apo_druid)]
    end

    def collections_values
      [safe_join(collection_links, ', ')]
    end

    def projects_values
      [safe_join(project_links, ', ')]
    end

    def identifier_values
      [result.identifiers.join(', ')]
    end

    def released_to_values
      [result.released_to.to_sentence]
    end

    def ticket_values
      [safe_join(ticket_links, ', ')]
    end

    def workflow_error_values
      [
        tag.span(class: 'text-danger') do
          result.workflow_errors.join('; ')
        end
      ]
    end

    def access_rights_values
      [result.access_rights.join(', ')]
    end

    private

    def collection_links
      result.collection_druids.map.with_index do |collection_druid, index|
        helpers.link_to_item(result.collection_titles[index], collection_druid)
      end
    end

    def project_links
      result.projects.map do |project|
        search_form = Search::ItemForm.new(projects: [project])
        helpers.link_to(project,
                        search_items_path(search_form.with_attributes(page: nil)), data: { turbo_frame: '_top' })
      end
    end

    def ticket_links
      result.tickets.map do |ticket|
        search_form = Search::ItemForm.new(tickets: [ticket])
        helpers.link_to(ticket,
                        search_items_path(search_form.with_attributes(page: nil)), data: { turbo_frame: '_top' })
      end
    end
  end
end
