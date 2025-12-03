# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetTurboStreamReplaceComponent, type: :component do
  let(:component) { described_class.new(facet_config:, facet_counts:, search_form:) }

  let(:facet_config) { Search::Facets::MIMETYPES }

  let(:search_form) { SearchForm.new(mimetypes: ['application/pdf'], page: 2) }
  let(:facet_counts) { instance_double(SearchResults::FacetCounts, page: 1, total_pages: 2) }
  let(:facet_count) { SearchResults::FacetCount.new(value: 'application/pdf', count: 10) }

  before do
    allow(facet_counts).to receive(:each)
      .and_yield(facet_count)
    allow(facet_counts).to receive_messages(to_ary: [facet_count], any?: true)
  end

  it 'renders the facet turbo stream replace component' do
    results = render_inline(component)

    expect(page).to have_css("turbo-stream[action='replace'][target='#{facet_config.form_field}-facet']")
    # The content inside the template is not available to Capybara for some reason.
    expect(results.to_html).to include('<section aria-label="MIME types"')
  end

  context 'when a checkbox facet component is specified' do
    let(:component) do
      described_class.new(facet_config:, facet_counts:, search_form:, facet_component: :checkbox)
    end

    it 'renders the checkbox facet component inside the turbo stream' do
      results = render_inline(component)

      expect(page).to have_css("turbo-stream[action='replace'][target='#{facet_config.form_field}-facet']")
      # The content inside the template is not available to Capybara for some reason.
      expect(results.to_html).to include('<section aria-label="MIME types"')
      expect(results.to_html).to include('<input type="submit" name="commit" value="Filter"')
    end
  end

  context 'when an invalid facet component is specified' do
    let(:component) do
      described_class.new(facet_config:, facet_counts:, search_form:, facet_component: :invalid)
    end

    it 'raises an ArgumentError' do
      expect { render_inline(component) }.to raise_error(ArgumentError, 'unexpected facet_component')
    end
  end

  context 'with a provided facet component' do
    it 'renders the provided facet component inside the turbo stream' do
      results = render_inline(component) do |comp|
        comp.with_facet { '<div class="custom-facet">Custom Facet Content</div>'.html_safe }
      end

      expect(page).to have_css("turbo-stream[action='replace'][target='#{facet_config.form_field}-facet']")
      expect(results.to_html).to include('<div class="custom-facet">Custom Facet Content</div>')
    end
  end
end
