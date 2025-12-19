# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::SelectSourceComponent, type: :component do
  let(:component) { described_class.new(form:, search_form:, total_results:) }

  let(:form) { ActionView::Helpers::FormBuilder.new(nil, bulk_action_form, vc_test_view_context, {}) }
  let(:search_form) { nil }
  let(:total_results) { nil }
  let(:bulk_action_form) { BulkActions::BasicForm.new }

  context 'when no search form is provided' do
    it 'renders the select source form without last search option' do
      render_inline(component)

      expect(page).to have_css('fieldset legend', text: 'Select source of items for bulk action')
      expect(page).to have_field('From last search', type: 'radio', disabled: true)

      expect(page).to have_field('From druid list', type: 'radio', checked: true)
      expect(page).to have_field('Enter druid list', type: 'textarea')
    end
  end

  context 'when last search form is provided' do
    let(:search_form) { SearchForm.new(query: 'test') }
    let(:total_results) { 42 }
    let(:bulk_action_form) { BulkActions::BasicForm.new(source: 'results') }

    it 'renders the select source form with last search option' do
      render_inline(component)

      expect(page).to have_css('fieldset legend', text: 'Select source of items for bulk action')
      expect(page).to have_field('From last search', type: 'radio', checked: true)
      expect(page).to have_css('p', text: '42 items for: "test"')

      expect(page).to have_field('From druid list', type: 'radio', checked: false)
      expect(page).to have_field('Enter druid list', type: 'textarea')
    end
  end
end
