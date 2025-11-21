# frozen_string_literal: true

module Search
  # Controller for project searches
  class ProjectsController < SearchApplicationController
    def index
      @search_form = build_form(form_class: Search::Form)
      @project_tags = Searchers::Tag.call(search_form: @search_form, field: Search::Fields::PROJECT_TAGS)
    end
  end
end
