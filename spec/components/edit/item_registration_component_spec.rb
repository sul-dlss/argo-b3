# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::ItemRegistrationComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:item_registration, item_registration_form, vc_test_view_context, {}) }
  let(:item_registration_form) do
    ItemRegistrationForm.new(title: 'A title', source_id: 'sul:1234', barcode: '36105212345678')
  end

  it 'renders text fields for title, source ID, barcode, and catalog record ID' do
    render_inline(component)

    expect(page).to have_field('Title', type: 'text', with: 'A title')
    expect(page).to have_field('Source ID', type: 'text', with: 'sul:1234')
    expect(page).to have_field('Barcode', type: 'text', with: '36105212345678')
    expect(page).to have_field('Folio instance HRID', type: 'text')
  end
end
