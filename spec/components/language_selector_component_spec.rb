# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LanguageSelectorComponent, type: :component do
  let(:component) { described_class.new(form:) }

  let(:form) { ActionView::Helpers::FormBuilder.new(nil, bulk_action_form, vc_test_view_context, {}) }
  let(:bulk_action_form) { BulkActions::TextExtractionForm.new }

  it 'renders a multiple select wired up to the multi-select controller' do
    render_inline(component)

    expect(page).to have_css('div[data-controller="multi-select"][data-multi-select-max-recommended-value="8"]')
    expect(page).to have_css('label', text: 'Search for a language')
    expect(page).to have_css('select[multiple][data-multi-select-target="select"]')
  end

  it 'renders an option for each Abbyy language with punctuation stripped from the value' do
    render_inline(component)

    expect(page).to have_css('select option', count: described_class::ABBYY_LANGUAGES.size)
    expect(page).to have_css('select option[value="English"]', text: 'English')
    expect(page).to have_css('select option[value="ArmenianEastern"]', text: 'Armenian (Eastern)')
  end

  it 'renders the too-many-languages warning hidden' do
    render_inline(component)

    expect(page).to have_css('.d-none[data-multi-select-target="warning"]',
                             text: 'Selecting more than eight text-extraction languages')
  end

  context 'when languages are already selected' do
    let(:bulk_action_form) { BulkActions::TextExtractionForm.new(text_extraction_languages: %w[English Danish]) }

    it 'marks those options as selected' do
      render_inline(component)

      expect(page).to have_css('select option[selected]', count: 2, visible: :all)
      expect(page).to have_css('select option[value="English"][selected]', visible: :all)
      expect(page).to have_css('select option[value="Danish"][selected]', visible: :all)
    end
  end
end
