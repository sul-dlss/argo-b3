# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetTurboStreamReplaceComponent, type: :component do
  let(:component) { described_class.new(facet_config: Search::Facets::OBJECT_TYPES, results:, search_form:) }

  let(:search_form) { ResultsSearchForm.new }
  let(:results) { SearchResults::Items.new(solr_response:, per_page: 0) }
  let(:solr_response) do
    {
      'responseHeader' => {
        'params' => { 'json.facet' => { Search::Fields::OBJECT_TYPES => { limit: 100 } }.to_json }
      },
      'response' => { 'numFound' => 1, 'start' => 0, 'docs' => [] },
      'facets' => { Search::Fields::OBJECT_TYPES => { 'numBuckets' => 1, 'buckets' => [{ 'val' => 'item', 'count' => 10 }] } }
    }
  end

  it 'replaces the facet placeholder with the facet from the results' do
    results = render_inline(component)

    expect(page).to have_css("turbo-stream[action='replace'][target='object-types-facet']")
    # The content inside the template is not available to Capybara.
    expect(results.to_html).to include('<section aria-label="Object type"')
    expect(results.to_html).to include('value="item"')
  end
end
