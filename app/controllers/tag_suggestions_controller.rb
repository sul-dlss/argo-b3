# frozen_string_literal: true

# Controller for tag suggestions, e.g., for a Tom Select tag field that suggests existing tags as the user types.
class TagSuggestionsController < ApplicationController
  # The suggestions are restricted to the tags of objects the user can see.
  skip_verify_authorized

  def index
    query = params.require(:q)
    tag_type = params.require(:type)
    return head :bad_request unless Searchers::TagSuggestions::TAG_TYPES.include?(tag_type)

    tags = Searchers::TagSuggestions.call(query:, tag_type:, user_scope: current_user_scope)
    render json: tags.map { |tag| { value: tag, text: tag } }
  end
end
