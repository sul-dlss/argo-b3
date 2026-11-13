# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::AdvancedFormComponent, type: :component do
  it 'renders a separate query input and retains selected facets when submitting' do
    render_inline(described_class.new(search_form: AdvancedSearchForm.new(query: 'Miller OR octopus',
                                                                          projects: ['Google Books'], page: 3)))

    expect(page).to have_css('form[action="/advanced_search"][method="get"]')
    expect(page).to have_field('Advanced query', type: :text, with: 'Miller OR octopus')
    expect(page).to have_field('projects[]', type: :hidden, with: 'Google Books')
    expect(page).to have_no_field('page', type: :hidden)
    expect(page).to have_button('Run advanced search', exact: true)
    expect(page).to have_text('Use uppercase AND, OR, NOT')
  end
end
