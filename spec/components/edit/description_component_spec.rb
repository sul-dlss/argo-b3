# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::DescriptionComponent, type: :component do
  let(:component) { described_class.new(form:, druid_token: 'abc123') }
  let(:form) { ActionView::Helpers::FormBuilder.new(:item, edit_item_form, vc_test_view_context, {}) }
  let(:edit_item_form) { EditItemForm.new(catalog_record_id: 'in11403803', catalog_link_refresh: true) }

  it 'renders the description fields' do
    render_inline(component)

    expect(page).to have_field('FOLIO Instance HRID', type: 'text', with: 'in11403803')
    expect(page).to have_field('Refresh on deposit', type: 'checkbox', checked: true)
    expect(page).to have_css('fieldset legend', text: 'Additional FOLIO Instance HRIDs')
    expect(page).to have_field('Barcode', type: 'text')
    expect(page).to have_css('fieldset legend', text: 'Serials')
    expect(page).to have_field('item[description_csv_file]', type: 'file')
    expect(page).to have_css('[data-controller="disable-when-checked"]')
    expect(page).to have_text('once you click "Save as draft."')
  end

  context 'without the item fields' do
    let(:component) { described_class.new(form:, druid_token: 'abc123', item_fields: false) }
    let(:form) { ActionView::Helpers::FormBuilder.new(:collection, edit_collection_form, vc_test_view_context, {}) }
    let(:edit_collection_form) { EditCollectionForm.new(catalog_record_id: 'in11403803') }

    it 'renders the description fields without barcode, serials, or the draft note' do
      render_inline(component)

      expect(page).to have_field('FOLIO Instance HRID', type: 'text', with: 'in11403803')
      expect(page).to have_field('Refresh on deposit', type: 'checkbox', checked: false)
      expect(page).to have_css('fieldset legend', text: 'Additional FOLIO Instance HRIDs')
      expect(page).to have_field('collection[description_csv_file]', type: 'file')
      expect(page).to have_no_field('Barcode')
      expect(page).to have_no_css('fieldset legend', text: 'Serials')
      expect(page).to have_no_text('Save as draft')
    end
  end
end
