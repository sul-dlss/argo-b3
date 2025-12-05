# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Report::FieldsSectionComponent, type: :component do
  let(:component) { described_class.new(form:, label: 'Frequently used', field_configs: ReportsController::FREQUENTLY_USED_FIELDS, classes: 'my-class') }

  let(:form) { ActionView::Helpers::FormBuilder.new(nil, report_form, vc_test_view_context, {}) }
  let(:report_form) { ReportForm.new(fields: [Reports::Fields::DRUID.field]) }

  it 'renders the section with checkboxes' do
    render_inline(component)

    expect(page).to have_css('div.fst-italic.my-class', text: 'Frequently used')

    expect(page).to have_css("input.form-check-input[type=\"checkbox\"][value=\"#{Reports::Fields::DRUID.field}\"][checked]")
    expect(page).to have_css('label.form-check-label', text: 'Druid')
    expect(page).to have_css('small.form-text.text-muted', text: 'For example: pj757vx3102')

    expect(page).to have_css("input.form-check-input[type=\"checkbox\"][value=\"#{Reports::Fields::TITLE.field}\"]:not([checked])")
    expect(page).to have_css('label.form-check-label', text: 'Title')
  end
end
