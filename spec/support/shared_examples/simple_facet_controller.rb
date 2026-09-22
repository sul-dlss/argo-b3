# frozen_string_literal: true

# Shared examples for simple facet controllers (genre, language, region, etc.)
# that delegate index/search entirely to FacetsApplicationController.
#
# Usage:
#   it_behaves_like 'a simple facet controller',
#     index_path: :search_genre_facets_path,
#     search_path: :search_search_genre_facets_path,
#     facet_frame_fragment: 'turbo-frame id="genres-facet-page1"',
#     facet_value: 'Maps',
#     search_query: 'maps'
#
# `facet_label:` is only needed for composite facets, where the displayed text (a title) differs
# from `facet_value:` (the druid used for filtering/data-autocomplete-value). It defaults to `facet_value:`.
RSpec.shared_examples 'a simple facet controller' do |index_path:, search_path:, # rubocop:disable Metrics/ParameterLists
                                                       facet_frame_fragment:, facet_value:, search_query:,
                                                       facet_label: nil|
  describe 'index' do
    it 'returns facet values' do
      get send(index_path), params: { query: 'test', facet_page: 1 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(facet_frame_fragment)
      expect(response.body).to include(facet_label || facet_value)
    end
  end

  describe 'search' do
    it 'returns search results' do
      get send(search_path), params: { query: 'test', q: search_query }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("data-autocomplete-value=\"#{facet_value}\"")
    end
  end
end
