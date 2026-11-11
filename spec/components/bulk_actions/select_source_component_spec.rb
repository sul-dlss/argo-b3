# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::SelectSourceComponent, type: :component do
  let(:component) { described_class.new(form:, search_form:, total_results:, example_druids:) }

  let(:form) { ActionView::Helpers::FormBuilder.new(nil, bulk_action_form, vc_test_view_context, {}) }
  let(:search_form) { nil }
  let(:total_results) { nil }
  let(:example_druids) { [] }
  let(:bulk_action_form) { BulkActions::BasicForm.new }

  context 'when no search form is provided' do
    it 'renders the select source form without last search option' do
      render_inline(component)

      expect(page).to have_css('fieldset legend', text: 'Select source of items for bulk action')
      expect(page).to have_field('From last search', type: 'radio', disabled: true)

      expect(page).to have_field('From druid list', type: 'radio', checked: true)
      expect(page).to have_field('Enter druid list', type: 'textarea')
      expect(page).to have_no_text('including')
    end
  end

  context 'when last search form is provided' do
    let(:search_form) { ResultsSearchForm.new(query: 'test') }
    let(:total_results) { 12_345 }
    let(:example_druids) { ['druid:bc123df4567', 'druid:fg890hj1234'] }
    let(:bulk_action_form) { BulkActions::BasicForm.new(source: 'results') }

    it 'renders the select source form with last search option' do
      render_inline(component)

      expect(page).to have_css('fieldset legend', text: 'Select source of items for bulk action')
      expect(page).to have_field('From last search', type: 'radio', checked: true)
      expect(page).to have_css('p', text: '12,345 items for: "test", including bc123df4567, fg890hj1234...')
      expect(page).to have_link('bc123df4567', href: '/objects/druid:bc123df4567')
      expect(page).to have_link('fg890hj1234', href: '/objects/druid:fg890hj1234')

      expect(page).to have_field('From druid list', type: 'radio', checked: false)
      expect(page).to have_field('Enter druid list', type: 'textarea')
    end
  end

  context 'when a label and Stimulus options are provided' do
    let(:component) do
      described_class.new(form:, label: 'Select source of items for report', radio_action: 'report#updateSubmit',
                          druids_radio_data: { report_target: 'sourceRadio' },
                          druid_list_data: { report_target: 'druidListInput' })
    end

    it 'renders the label and adds the Stimulus attributes' do
      render_inline(component)

      expect(page).to have_css('fieldset legend', exact_text: 'Select source of items for report', normalize_ws: true)
      expect(page).to have_css('input[value="results"][data-action="radio#toggle report#updateSubmit"]')
      expect(page).to have_css(
        'input[value="druids"][data-action="radio#toggle report#updateSubmit"][data-report-target="sourceRadio"]'
      )
      expect(page).to have_css('textarea[data-report-target="druidListInput"]')
    end
  end

  context 'when the example druids are all of the results' do
    let(:search_form) { ResultsSearchForm.new(query: 'test') }
    let(:total_results) { 2 }
    let(:example_druids) { ['druid:bc123df4567', 'druid:fg890hj1234'] }

    it 'renders the example druids without an ellipsis' do
      render_inline(component)

      expect(page).to have_css('p', text: 'including bc123df4567, fg890hj1234')
      expect(page).to have_no_text('...')
    end
  end

  context 'when the source has an error' do
    before { bulk_action_form.errors.add(:source, 'is invalid') }

    it 'renders the error once for the radio buttons' do
      render_inline(component)

      expect(page).to have_css('#source_error.invalid-feedback', text: 'is invalid', count: 1)
      expect(page).to have_css('input[type="radio"][aria-invalid="true"][aria-describedby~="source_error"]', count: 2)
    end
  end
end
