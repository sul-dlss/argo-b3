# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::SerialsComponent, type: :component do
  let(:form) { ActionView::Helpers::FormBuilder.new(nil, new_item_form, vc_test_view_context, {}) }
  let(:new_item_form) { NewItemForm.new(catalog_link_part_label: 'v. 1', catalog_link_sort_key: '1') }

  it 'renders the part label and sort key fields' do
    render_inline(described_class.new(form:))

    expect(page).to have_css('fieldset legend', text: 'Serials')
    expect(page).to have_field('Part label', type: 'text', with: 'v. 1')
    expect(page).to have_field('Sort key', type: 'text', with: '1')
  end
end
