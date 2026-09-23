# frozen_string_literal: true

module Search
  # Component to render a single item result in search results
  class ItemResultComponent < ViewComponent::Base
    with_collection_parameter :result

    # @param result [SearchResults::Item]
    def initialize(result:, pinned_object_druids:)
      @result = result
      @pinned_object_druids = pinned_object_druids
      super()
    end

    attr_reader :result, :pinned_object_druids

    delegate :title, :druid, :bare_druid, :index, to: :result

    def id
      "item-result-#{bare_druid}"
    end

    def content_type_values
      [result.content_type.capitalize]
    end

    def admin_policy_values
      [helpers.link_to_object(result.apo_title, result.apo_druid, data: { turbo_frame: '_top' })]
    end

    def collections_values
      [safe_join(collection_links, ', ')]
    end

    def projects_values
      [safe_join(project_links, ', ')]
    end

    def released_to_values
      return ['Not released'] if result.released_to.blank?

      [result.released_to.to_sentence]
    end

    def tag_values
      [safe_join(tag_links, ', ')]
    end

    def display_tags
      Array(result.all_tags).reject do |tag|
        tag.start_with?(ProjectTagForm::PROJECT_TAG_PREFIX, TicketTagForm::TICKET_TAG_PREFIX)
      end
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
      [result.access_rights.map(&:capitalize).join(', ')]
    end

    def pinnable?
      result.object_type != 'agreement'
    end

    def pinned?
      pinned_object_druids.include?(druid)
    end

    private

    def collection_links
      result.collection_druids.map.with_index do |collection_druid, index|
        helpers.link_to_object(result.collection_titles[index], collection_druid, data: { turbo_frame: '_top' })
      end
    end

    def project_links
      result.projects.map do |project|
        search_form = ResultsSearchForm.new(projects: [project])
        helpers.link_to(project, helpers.url_for(search_form), data: { turbo_frame: '_top' })
      end
    end

    def ticket_links
      result.tickets.map do |ticket|
        search_form = ResultsSearchForm.new(tickets: [ticket])
        helpers.link_to(ticket, helpers.url_for(search_form), data: { turbo_frame: '_top' })
      end
    end

    def tag_links
      display_tags.map do |tag|
        search_form = ResultsSearchForm.new(tags: [tag])
        helpers.link_to(tag, helpers.url_for(search_form), data: { turbo_frame: '_top' })
      end
    end
  end
end
