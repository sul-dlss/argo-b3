# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::DebugComponent, type: :component do
  let(:component) { described_class.new(search_form:, results:) }

  let(:solr_response) { { 'response' => { 'numFound' => 5, 'docs' => [] } } }
  let(:results) { SearchResults::Items.new(solr_response:, per_page: 20) }

  context 'when debug is true' do
    let(:search_form) { Search::Form.new(debug: true) }

    it 'renders the solr response' do
      render_inline(component)

      expect(page).to have_css('pre', text: JSON.pretty_generate(solr_response))
    end
  end

  context 'when debug is false' do
    let(:search_form) { Search::Form.new(debug: false) }

    it 'does not render anything' do
      expect(component.render?).to be false
    end
  end
end
