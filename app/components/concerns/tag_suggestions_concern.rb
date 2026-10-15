# frozen_string_literal: true

# Provides the data attributes for a tag input that suggests existing tags as the user types
# (see app/javascript/controllers/tag_select_controller.js). Including components define
# suggest? and tag_type (one of Searchers::TagSuggestions::TAG_TYPES).
module TagSuggestionsConcern
  extend ActiveSupport::Concern

  def input_data
    return {} unless suggest?

    {
      controller: 'tag-select',
      tag_select_url_path_value: tag_suggestions_path(type: tag_type),
      action: 'input->tag-select#sync'
    }
  end
end
