# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::ApoComponent, type: :component do
  let(:component) { described_class.new(form:, options:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:item, new_item_form, vc_test_view_context, {}) }
  let(:new_item_form) { NewItemForm.new(apo_druid: 'druid:bc123df4567') }
  let(:options) { [['APO One', 'druid:bc123df4567'], ['APO Two', 'druid:xz987wv6543']] }

  it 'renders the APO select' do
    render_inline(component)

    expect(page).to have_select('APO', selected: 'APO One', options: ['APO One', 'APO Two'])
  end

  context 'when applying APO defaults' do
    let(:component) { described_class.new(form:, options:, apo_defaults: true) }

    it 'renders the targets that the apo-defaults Stimulus controller expects' do
      render_inline(component)

      expect(page).to have_css('select[data-apo-defaults-target="apo"][data-action="apo-defaults#apply"]')
      expect(page).to have_css('option[value="druid:bc123df4567"]' \
                               '[data-apo-defaults-url="/apo_defaults/druid:bc123df4567"]')
      expect(page).to have_css('option[value="druid:xz987wv6543"]' \
                               '[data-apo-defaults-url="/apo_defaults/druid:xz987wv6543"]')
    end
  end
end
