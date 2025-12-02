# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::LoadingFacetDivComponent, type: :component do
  let(:component) { described_class.new(facet_config: Search::Facets::OBJECT_TYPES) }

  it 'renders the loading facet div component' do
    render_inline(component)

    expect(page).to have_css('div#object-types-facet h3', text: 'Object types')
  end
end
