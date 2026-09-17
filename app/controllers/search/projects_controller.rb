# frozen_string_literal: true

module Search
  # Controller for project searches
  class ProjectsController < SearchApplicationController
    layout false

    def index
      @project_tags = Searchers::Tag.call(search_form: @search_form, field: Search::Fields::PROJECTS_EXPLODED,
                                          user_scope: current_user_scope)
    end
  end
end
