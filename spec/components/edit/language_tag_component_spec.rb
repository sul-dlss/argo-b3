# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::LanguageTagComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:content_file, content_file_form, vc_test_view_context, {}) }
  let(:content_file_form) { ContentFileForm.new(language_tag:) }
  let(:language_tag) { 'de' }

  it 'renders the language select' do
    render_inline(component)

    expect(page).to have_select('Language', selected: 'de', options: described_class::LANGUAGE_TAGS)
    expect(page).to have_css('select[data-controller="creatable-select"]')
  end

  context 'when the language tag is not a common one' do
    let(:language_tag) { 'en-US' }

    it 'adds the language tag as an option' do
      render_inline(component)

      expect(page).to have_select('Language', selected: 'en-US', with_options: %w[en-US en])
    end
  end

  context 'when there is no language tag' do
    let(:language_tag) { nil }

    it 'prompts for a language tag' do
      render_inline(component)

      expect(page).to have_css('select option:first-child[value=""]', text: 'Select or enter a language')
      expect(page).to have_no_css('select option[selected]')
    end
  end
end
