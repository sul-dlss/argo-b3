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
    expect(page).to have_no_button('Apply APO defaults')
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
      expect(page).to have_no_button('Apply APO defaults')
    end
  end

  context 'when applying APO defaults with a button' do
    let(:component) { described_class.new(form:, options:, apo_defaults: true, apply_defaults_button: true) }

    it 'renders the APO select and the button that applies the defaults' do
      render_inline(component)

      expect(page).to have_select('APO', selected: 'APO One', options: ['APO One', 'APO Two'])
      expect(page).to have_css('select[aria-required="true"]')
      expect(page).to have_css('select[data-apo-defaults-target="apo"][data-action="apo-defaults#refresh"]')
      expect(page).to have_css('option[value="druid:bc123df4567"]' \
                               '[data-apo-defaults-url="/apo_defaults/druid:bc123df4567"]')
      expect(page).to have_button('Apply APO defaults', type: 'button')
      expect(page).to have_css('button[data-action="apo-defaults#apply"]', text: 'Apply APO defaults')
    end
  end

  context 'when the button is requested without applying APO defaults' do
    let(:component) { described_class.new(form:, options:, apply_defaults_button: true) }

    it 'renders no button' do
      render_inline(component)

      expect(page).to have_select('APO')
      expect(page).to have_no_button('Apply APO defaults')
    end
  end
end
