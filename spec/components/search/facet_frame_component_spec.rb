# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetFrameComponent, type: :component do
  let(:component) { described_class.new(facet_config: Search::Facets::TICKETS, facet_counts:, search_form:) }

  let(:search_form) { ResultsSearchForm.new }
  let(:facet_counts) { instance_double(SearchResults::FacetCounts, page: 1, total_pages: 1, any?: true) }

  before do
    allow(facet_counts).to receive(:each).and_yield(SearchResults::FacetCount.new(value: 'TESTREQ-1', count: 3))
  end

  it 'renders the facet in a frame that targets the top' do
    render_inline(component)

    expect(page).to have_css('turbo-frame#tickets-facet[target="_top"] turbo-frame#tickets-facet-page1',
                             text: 'TESTREQ-1')
  end
end
