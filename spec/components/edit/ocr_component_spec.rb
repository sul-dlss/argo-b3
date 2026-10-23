# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::OcrComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:contents_item, contents_item_form, vc_test_view_context, {}) }
  let(:contents_item_form) do
    ContentsItemForm.build_from_cocina_object(build(:dro_with_metadata, type: Cocina::Models::ObjectType.book))
  end

  it 'renders the Run OCR? radios with No selected' do
    render_inline(component)

    expect(page).to have_css('fieldset[data-ocr-options-target="section"]')
    expect(page).to have_css('legend', text: 'Run OCR?')
    expect(page).to have_field('Yes', type: 'radio', checked: false)
    expect(page).to have_field('No', type: 'radio', checked: true)
    expect(page.all('input[type="radio"]').map(&:value)).to eq(%w[false true])
  end

  it 'wires the radios up to the ocr-options controller' do
    render_inline(component)

    expect(page).to have_css(
      'input[type="radio"][data-ocr-options-target="performOcr"][data-action="ocr-options#toggle"]', count: 2
    )
  end

  it 'renders the language selector as the ocr-options dependent within the Yes option' do
    render_inline(component)

    expect(page).to have_css('label', text: 'Search for a language')
    expect(page).to have_css('.form-check:has(input[value="true"]) ' \
                             'div[data-controller="multi-select"][data-ocr-options-target="languages"]')
  end

  it 'renders the embedded text info alert hidden, scoped to documents, within the Yes option' do
    render_inline(component)

    warn_for = [Cocina::Models::ObjectType.document].to_json
    expect(page).to have_css(".form-check:has(input[value='true']) .alert-info.d-none" \
                             "[data-ocr-options-target='warning']" \
                             "[data-ocr-options-warn-content-types='#{warn_for}']",
                             text: 'Do not run OCR for files that already have embedded text.')
  end

  context 'when OCR has been requested' do
    let(:contents_item_form) do
      super().tap { |form| form.update(perform_ocr: true, ocr_languages: ['English']) }
    end

    it 'selects Yes and the chosen languages' do
      render_inline(component)

      expect(page).to have_field('Yes', type: 'radio', checked: true)
      expect(page).to have_css('select option[value="English"][selected]', visible: :all)
    end
  end
end
