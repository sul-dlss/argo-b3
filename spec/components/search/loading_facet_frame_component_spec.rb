# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::LoadingFacetFrameComponent, type: :component do
  let(:component) { described_class.new(search_form: Search::ItemForm.new, facet_config: Search::Facets::PROJECTS) }

  it 'renders the loading facet frame component' do
    render_inline(component)

    expect(page).to have_css("turbo-frame#projects-facet[src='/search/project_facets'] h3", text: 'Projects')
  end
end
