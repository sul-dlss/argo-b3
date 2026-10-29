# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetYearRangeComponent, type: :component do
  let(:component) do
    described_class.new(search_form:, year_from_form_field: :dates_from, year_to_form_field: :dates_to)
  end
  let(:search_form) do
    ResultsSearchForm.new(query: 'maps', dates: ['2001'], dates_from: '1999', dates_to: '2001', page: 2)
  end

  it 'renders the year range form' do
    render_inline(component)

    form = page.find('form[action="/search"][method="get"]')
    expect(form).to have_field('From', type: 'number', with: '1999')
    expect(form).to have_css('input[name="dates_from"][min="-9999"][max="9999"]')
    expect(form).to have_field('To', type: 'number', with: '2001')
    expect(form).to have_css('input[name="dates_to"][min="-9999"][max="9999"]')
    expect(form).to have_button('Filter')

    # The rest of the search is retained.
    expect(form).to have_field('query', type: 'hidden', with: 'maps')
    expect(form).to have_field('dates[]', type: 'hidden', with: '2001')
    expect(form).to have_no_field('page', type: 'hidden')
    # The year range is not duplicated by hidden fields (which would also take over the inputs' ids and labels).
    expect(form).to have_css('#dates_from', count: 1)
    expect(form).to have_css('#dates_to', count: 1)
    expect(form).to have_no_field('dates_from[]', type: 'hidden')
    expect(form).to have_no_field('dates_to[]', type: 'hidden')
  end

  context 'without year range form fields' do
    let(:component) { described_class.new(search_form:, year_from_form_field: nil, year_to_form_field: nil) }

    it 'does not render the component' do
      expect(component.render?).to be false
    end
  end
end
