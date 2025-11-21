# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetPageLinkComponent, type: :component do
  let(:component) do
    described_class.new(facet_counts:, search_form:, facet_path_helper:, form_field:)
  end
  let(:facet_counts) { instance_double(SearchResults::FacetCounts, page: current_page, total_pages:) }
  let(:search_form) { Search::ItemForm.new }
  let(:facet_path_helper) { Search::Facets::MIMETYPES.facet_path_helper }
  let(:form_field) { :mimetypes }
  let(:current_page) { 1 }
  let(:total_pages) { 3 }

  it 'renders the next page link when there is a next page' do
    render_inline(component)

    turbo_frame = page.find('turbo-frame#mimetypes-facet-page2')
    expect(turbo_frame).to have_link('More',
                                     href: '/search/mimetype_facets?facet_page=2')
  end

  context 'when on the last page' do
    let(:current_page) { 3 }

    it 'does not render the next page link' do
      expect(component.render?).to be false
    end
  end

  context 'when no facet_path_helper is provided' do
    let(:facet_path_helper) { nil }

    it 'does not render the next page link' do
      expect(component.render?).to be false
    end
  end
end
