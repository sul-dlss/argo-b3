# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::AdditionalCatalogRecordIdComponent, type: :component do
  let(:form) do
    ActionView::Helpers::FormBuilder.new('item[additional_folio_catalog_links_attributes][0]',
                                         AdditionalCatalogRecordIdForm.new(catalog_record_id: 'in111'),
                                         vc_test_view_context, {})
  end

  it 'renders the catalog record id field with a preview button' do
    render_inline(described_class.new(form:))

    expect(page).to have_field('Additional FOLIO Instance HRID', type: 'text', with: 'in111')
    expect(page).to have_css('label.visually-hidden', text: 'Additional FOLIO Instance HRID')
    expect(page).to have_no_text('Required')
    expect(page).to have_css('[data-controller="catalog-title"]')
    expect(page).to have_button('Preview FOLIO record')
    expect(page).to have_field('item[additional_folio_catalog_links_attributes][0][retrieved_title]', type: :hidden)
  end
end
