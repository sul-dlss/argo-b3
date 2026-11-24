# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetOperatorToggleComponent, type: :component do
  let(:component) do
    described_class.new(search_form:, form_field: :languages, operator_form_field: :languages_operator)
  end
  let(:search_form) { ResultsSearchForm.new(languages: %w[English Spanish], page: 2) }

  it 'renders a labelled And/Or group with Or checked by default' do
    render_inline(component)

    label_id = page.find('label', text: 'Combine selected languages with', visible: :all)[:id]
    expect(page).to have_css("[role='group'][aria-labelledby='#{label_id}']")
    expect(page).to have_unchecked_field('And')
    expect(page).to have_checked_field('Or')
  end

  it 'visits the search with each operator' do
    render_inline(component)

    expect(page).to have_field('And') do |field|
      field['data-action'] == 'change->visit#visit' &&
        field['data-visit-url-param'] ==
          '/search?languages%5B%5D=English&languages%5B%5D=Spanish&languages_operator=and'
    end
    expect(page).to have_field('Or') do |field|
      field['data-visit-url-param'] == '/search?languages%5B%5D=English&languages%5B%5D=Spanish'
    end
  end

  context 'when And is chosen' do
    let(:search_form) { ResultsSearchForm.new(languages_operator: 'and') }

    it 'checks And' do
      render_inline(component)

      expect(page).to have_checked_field('And')
      expect(page).to have_unchecked_field('Or')
    end
  end
end
