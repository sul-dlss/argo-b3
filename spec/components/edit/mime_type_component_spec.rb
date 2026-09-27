# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::MimeTypeComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:content_file, content_file_form, vc_test_view_context, {}) }
  let(:content_file_form) { ContentFileForm.new(mime_type:) }
  let(:mime_type) { 'image/jp2' }

  it 'renders the MIME type select' do
    render_inline(component)

    expect(page).to have_select('MIME type', selected: 'image/jp2', options: described_class::MIME_TYPES)
    expect(page).to have_css('select[data-controller="creatable-select"]')
  end

  context 'when the MIME type is not a common one' do
    let(:mime_type) { 'image/x-custom' }

    it 'adds the MIME type as an option' do
      render_inline(component)

      expect(page).to have_select('MIME type', selected: 'image/x-custom',
                                               with_options: ['image/x-custom', 'image/jp2'])
    end
  end

  context 'when there is no MIME type' do
    let(:mime_type) { nil }

    it 'prompts for a MIME type' do
      render_inline(component)

      expect(page).to have_css('select option:first-child[value=""]', text: 'Select or enter a MIME type')
      expect(page).to have_no_css('select option[selected]')
    end
  end
end
