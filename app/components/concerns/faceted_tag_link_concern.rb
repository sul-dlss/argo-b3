# frozen_string_literal: true

# Provides a search path for a tag, routing tags with a recognized prefix (e.g., "Ticket : ...",
# "Project : ...") to that facet's search path (with the prefix stripped) instead of the
# generic tags search path, since those tags are indexed into their own facet field.
module FacetedTagLinkConcern
  extend ActiveSupport::Concern

  FACETED_TAG_PREFIXES = {
    'Ticket' => :tickets,
    'Project' => :projects
  }.freeze

  def search_path_for(tag)
    prefix, value = tag.split(' : ', 2)
    form_field = FACETED_TAG_PREFIXES[prefix]
    return url_for(ResultsSearchForm.new(tags: [tag])) unless form_field && value

    url_for(ResultsSearchForm.new(form_field => [value]))
  end
end
