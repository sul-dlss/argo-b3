# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::CheckboxFacetValueComponent, type: :component do
  let(:component) do
    described_class.new(count: 27, search_form:, form_field: :languages, exclude_form_field:,
                        value: 'English', description_id: 'languages-facet-checkbox-description')
  end
  let(:exclude_form_field) { :languages_exclude }
  let(:checkbox) { page.find_field('English', type: 'checkbox') }

  context 'when not selected' do
    let(:search_form) { ResultsSearchForm.new(query: 'maps', page: 2) }

    it 'renders an unchecked checkbox that selects the value' do
      render_inline(component)

      expect(checkbox).not_to be_checked
      expect(checkbox['aria-describedby']).to eq('languages-facet-checkbox-description')
      expect(checkbox['data-visit-url-param']).to eq('/search?languages%5B%5D=English&query=maps')
      expect(page).to have_css('.facet-count', text: '27')
      expect(page).to have_link('Exclude English',
                                href: '/search?languages_exclude%5B%5D=English&query=maps')
    end
  end

  context 'when selected' do
    let(:search_form) { ResultsSearchForm.new(languages: %w[English French]) }

    it 'renders a checked checkbox that deselects the value, and an exclude link that switches it' do
      render_inline(component)

      expect(checkbox).to be_checked
      expect(page).to have_css('label.selected', text: 'English')
      expect(checkbox['data-visit-url-param']).to eq('/search?languages%5B%5D=French')
      expect(page).to have_link('Exclude English',
                                href: '/search?languages%5B%5D=French&languages_exclude%5B%5D=English')
    end
  end

  context 'when excluded' do
    let(:search_form) { ResultsSearchForm.new(languages_exclude: ['English']) }

    it 'renders the excluded value, with a checkbox that switches it to selected' do
      render_inline(component)

      expect(checkbox).not_to be_checked
      expect(page).to have_css('label del', text: 'English')
      expect(page).to have_css('.facet-count', text: '27')
      expect(page).to have_css('strong', text: 'excluded')
      expect(page).to have_no_link('Exclude English')
      expect(page).to have_link('Remove exclude English', href: '/search')
      expect(checkbox['data-visit-url-param']).to eq('/search?languages%5B%5D=English')
    end
  end

  context 'without exclude' do
    let(:exclude_form_field) { nil }
    let(:search_form) { ResultsSearchForm.new }

    it 'does not render an exclude link' do
      render_inline(component)

      expect(checkbox).not_to be_checked
      expect(page).to have_no_link('Exclude English')
    end
  end
end
