# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::ApoComponent, type: :component do
  let(:component) { described_class.new(form:, options:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:item, item_form, vc_test_view_context, {}) }
  let(:item_form) { ItemForm.new(apo_druid: 'druid:bc123df4567') }
  let(:options) { [['APO One', 'druid:bc123df4567'], ['APO Two', 'druid:xz987wv6543']] }

  it 'renders the APO select' do
    render_inline(component)

    expect(page).to have_select('APO', selected: 'APO One', options: ['APO One', 'APO Two'])
  end
end
