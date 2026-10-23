# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::CatalogRecordIdComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(nil, new_item_form, vc_test_view_context, {}) }
  let(:new_item_form) do
    NewItemForm.new(description_choice: NewItemForm::DESCRIPTION_CATALOG_ID_CHOICE, catalog_record_id: 'in11403803')
  end

  it 'renders the preview folio record button beside the HRID input and a hidden title' do
    render_inline(component)

    expect(page).to have_css('[data-controller="catalog-title"][data-catalog-title-url-value="/catalog_titles"]')
    expect(page).to have_field('FOLIO Instance HRID', type: 'text', with: 'in11403803')

    field_row = page.find('input[data-catalog-title-target="hrid"]').ancestor('.d-flex')
    expect(field_row).to have_button('Preview FOLIO record', type: 'button')
    expect(field_row).to have_no_css('.input-group')
    # Bootstrap reveals the message when the input is marked invalid, so it carries no d-block/d-none.
    expect(field_row).to have_css('div.invalid-feedback[data-catalog-title-target="error"]', visible: :all)
    expect(field_row).to have_no_css('[data-catalog-title-target="error"].d-block', visible: :all)

    # Hidden until a title is retrieved.
    expect(page).to have_css('[data-catalog-title-target="titleRow"][hidden]', visible: :all)
    expect(page.find('input[data-catalog-title-target="title"]', visible: :hidden)[:value]).to be_blank
  end

  context 'when a title has already been retrieved' do
    let(:new_item_form) do
      NewItemForm.new(description_choice: NewItemForm::DESCRIPTION_CATALOG_ID_CHOICE, catalog_record_id: 'in11403803',
                      retrieved_title: 'Pride and prejudice')
    end

    it 'renders the retrieved title as text' do
      render_inline(component)

      expect(page).to have_css('[data-catalog-title-target="titleRow"]:not([hidden])', text: 'Pride and prejudice')
      expect(page.find('input[data-catalog-title-target="title"]', visible: :hidden)[:value])
        .to eq('Pride and prejudice')
    end
  end
end
