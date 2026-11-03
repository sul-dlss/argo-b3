# frozen_string_literal: true

# Rendering and links for search views.
module SearchHelper
  def render_search_bar(current_search_form:, last_search_form:)
    search_form = current_search_form || last_search_form
    # No previous/last search or advanced search? then a new form
    # this is because advanced expressions belong in the advanced page's own input, not the global keyword bar
    search_form = ResultsSearchForm.new if search_form.nil? || search_form.is_a?(AdvancedSearchForm)

    render Search::FormComponent.new(search_form:, url: url_for(search_form))
  end

  def search_items_path_for(search_form)
    public_send("#{search_form.route_scope}_items_path", search_form.attributes)
  end
end
