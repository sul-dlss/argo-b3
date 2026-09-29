# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::UseComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:content_file, content_file_form, vc_test_view_context, {}) }
  let(:content_file_form) { ContentFileForm.new(use:) }
  let(:use) { 'derivative' }

  it 'renders the role select' do
    render_inline(component)

    expect(page).to have_select('Role', selected: 'derivative', options: described_class::USES)
    expect(page).to have_css('select[data-controller="creatable-select"]')
  end

  context 'when the use is not a common one' do
    let(:use) { 'supplement' }

    it 'adds the use as an option' do
      render_inline(component)

      expect(page).to have_select('Role', selected: 'supplement', with_options: %w[supplement transcription])
    end
  end

  context 'when there is no use' do
    let(:use) { nil }

    it 'prompts for a role' do
      render_inline(component)

      expect(page).to have_css('select option:first-child[value=""]', text: 'Select or enter a role')
      expect(page).to have_no_css('select option[selected]')
    end
  end
end
