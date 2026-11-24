# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::YearRangeComponent, type: :component do
  let(:component) { described_class.new(search_form:) }
  let(:search_form) do
    ResultsSearchForm.new(query: 'maps', dates: ['2001'], dates_from: '-10', dates_to: '2025', page: 2)
  end

  it 'renders the year range form, keeping the rest of the search' do
    render_inline(component)

    form = page.find('form[action="/search"][method="get"]')
    expect(form).to have_field('From', type: 'number', with: '-10')
    expect(form).to have_field('To', type: 'number', with: '2025')
    expect(form).to have_button('Filter')

    expect(form).to have_field('query', type: 'hidden', with: 'maps')
    expect(form).to have_field('dates[]', type: 'hidden', with: '2001')
    expect(form).to have_no_field('page', type: 'hidden')
    # The year range is submitted by the inputs, not also by hidden fields.
    expect(form).to have_no_field('dates_from', type: 'hidden')
    expect(form).to have_no_field('dates_to', type: 'hidden')
  end
end
