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
  end

  context 'without item fields' do
    let(:component) { described_class.new(form:, item_fields: false) }
    let(:form) { ActionView::Helpers::FormBuilder.new(:collection, new_collection_form, vc_test_view_context, {}) }
    let(:new_collection_form) do
      NewCollectionForm.new(description_choice: 'catalog_id', catalog_record_id: 'in11403803')
    end

    it 'renders the title and FOLIO choices without the item-only fields' do
      render_inline(component)

      expect(page).to have_field('Enter title myself', type: 'radio', checked: false)
      expect(page).to have_field('Retrieve description from FOLIO', type: 'radio', checked: true)
      expect(page).to have_field('collection[catalog_record_id]', type: 'text', with: 'in11403803')
      expect(page).to have_button('Preview FOLIO record')

      expect(page).to have_no_field('Barcode')
      expect(page).to have_no_field('Part label')
      expect(page).to have_no_field('Sort key')
      expect(page).to have_no_field('Upload description spreadsheet')
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
