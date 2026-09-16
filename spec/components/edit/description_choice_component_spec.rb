# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::DescriptionChoiceComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(nil, item_form, vc_test_view_context, {}) }

  context 'when the title is entered' do
    let(:item_form) { ItemForm.new(title: 'The Title') }

    it 'renders the title state' do
      render_inline(component)

      expect(page).to have_field('Enter title myself', type: 'radio', checked: true)
      expect(page).to have_field('Title', type: 'text', with: 'The Title')

      expect(page).to have_field('Use FOLIO Instance HRID to retrieve title', type: 'radio', checked: false)
      expect(page).to have_field('Upload description spreadsheet', type: 'radio', checked: false)
    end
  end

  context 'when the title is retrieved from the catalog' do
    let(:item_form) do
      ItemForm.new(description_choice: ItemForm::DESCRIPTION_CATALOG_ID_CHOICE, catalog_record_id: 'in11403803',
                   barcode: '36105010362304', catalog_link_part_label: 'v. 1', catalog_link_sort_key: '1')
    end

    it 'renders the catalog id state' do
      render_inline(component)

      expect(page).to have_field('Use FOLIO Instance HRID to retrieve title', type: 'radio', checked: true)
      expect(page).to have_field('Folio Instance HRID', type: 'text', with: 'in11403803')
      expect(page).to have_field('Barcode', type: 'text', with: '36105010362304')
      expect(page).to have_field('Part label', type: 'text', with: 'v. 1')
      expect(page).to have_field('Sort key', type: 'text', with: '1')

      expect(page).to have_field('Enter title myself', type: 'radio', checked: false)
    end
  end

  context 'when a description spreadsheet is uploaded' do
    let(:item_form) { ItemForm.new(description_choice: ItemForm::DESCRIPTION_SPREADSHEET_CHOICE) }

    it 'renders the spreadsheet state' do
      render_inline(component)

      expect(page).to have_field('Upload description spreadsheet', type: 'radio', checked: true)
      expect(page).to have_field('Upload a CSV file', type: 'file')

      expect(page).to have_field('Enter title myself', type: 'radio', checked: false)
    end
  end
end
