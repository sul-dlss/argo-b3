# frozen_string_literal: true

module Search
  # Controller for project searches
  class ProjectsController < SearchApplicationController
    layout false

    def index
      @search_form = build_form(form_class: SearchForm)
      @project_tags = Searchers::Tag.call(search_form: @search_form, field: Search::Fields::PROJECTS_EXPLODED)
    end
  end
end
