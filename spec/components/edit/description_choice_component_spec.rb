# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::DescriptionChoiceComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(nil, new_item_form, vc_test_view_context, {}) }

  context 'when the title is entered' do
    let(:new_item_form) { NewItemForm.new(title: 'The Title') }

    it 'renders the title state' do
      render_inline(component)

      expect(page).to have_field('Enter title myself', type: 'radio', checked: true)
      expect(page).to have_field('Title', type: 'text', with: 'The Title')

      expect(page).to have_field('Retrieve description from FOLIO', type: 'radio', checked: false)
      expect(page).to have_field('Upload description spreadsheet', type: 'radio', checked: false)
    end
  end

  context 'when the title is retrieved from the catalog' do
    let(:new_item_form) do
      NewItemForm.new(description_choice: NewItemForm::DESCRIPTION_CATALOG_ID_CHOICE, catalog_record_id: 'in11403803',
                      barcode: '36105010362304', catalog_link_part_label: 'v. 1', catalog_link_sort_key: '1')
    end

    it 'renders the catalog id state' do
      render_inline(component)

      expect(page).to have_field('Retrieve description from FOLIO', type: 'radio', checked: true)
      expect(page).to have_field('FOLIO Instance HRID', type: 'text', with: 'in11403803')
      expect(page).to have_field('Barcode', type: 'text', with: '36105010362304')
      expect(page).to have_field('Part label', type: 'text', with: 'v. 1')
      expect(page).to have_field('Sort key', type: 'text', with: '1')

      expect(page).to have_field('Enter title myself', type: 'radio', checked: false)
    end

    context 'when a title has already been retrieved' do
      let(:new_item_form) do
        NewItemForm.new(description_choice: NewItemForm::DESCRIPTION_CATALOG_ID_CHOICE, catalog_record_id: 'in11403803',
                        retrieved_title: 'Pride and prejudice')
      end

      it 'renders the retrieved title as text' do
        render_inline(component)

        expect(page).to have_text('Pride and prejudice')
      end
    end

    it 'renders the preview folio record button beside the HRID input and a hidden title' do
      render_inline(component)

      expect(page).to have_css('[data-controller="catalog-title"][data-catalog-title-url-value="/catalog_titles"]')

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
  end

  context 'when a description spreadsheet is uploaded' do
    let(:new_item_form) { NewItemForm.new(description_choice: NewItemForm::DESCRIPTION_SPREADSHEET_CHOICE) }

    it 'renders the spreadsheet state' do
      render_inline(component)

      expect(page).to have_field('Upload description spreadsheet', type: 'radio', checked: true)
      expect(page).to have_field('Upload a CSV file', type: 'file')

      expect(page).to have_field('Enter title myself', type: 'radio', checked: false)
    end
  end
end
