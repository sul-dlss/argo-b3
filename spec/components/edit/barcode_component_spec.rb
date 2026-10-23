# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::BarcodeComponent, type: :component do
  let(:form) { ActionView::Helpers::FormBuilder.new(nil, NewItemForm.new(barcode: '36105010362304'), vc_test_view_context, {}) }

  it 'renders the barcode field' do
    render_inline(described_class.new(form:))

    expect(page).to have_field('Barcode', type: 'text', with: '36105010362304')
    expect(page).to have_css('.my-field input[name="barcode"]')
  end
end
