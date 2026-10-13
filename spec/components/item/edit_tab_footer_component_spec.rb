# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Item::EditTabFooterComponent, type: :component do
  let(:pane) { SdrViewComponents::TabForm::PaneComponent.new(tab_name: :deposit, label: 'Deposit') }

  context 'without deposit' do
    it 'renders the navigation and the save as draft button' do
      render_inline(described_class.new(pane:, form_id: 'tabbed_form', cancel_path: '/objects/druid:bc123df4567'))

      expect(page).to have_link('Cancel', href: '/objects/druid:bc123df4567')
      expect(page).to have_button('Previous')
      expect(page).to have_button('Next')
      expect(page).to have_css('button[type="submit"][form="tabbed_form"][name="commit"][value="draft"]',
                               text: 'Save as draft')
      expect(page).to have_no_button('Deposit')
    end
  end

  context 'with deposit' do
    it 'renders the save as draft and deposit buttons' do
      render_inline(described_class.new(pane:, form_id: 'tabbed_form', cancel_path: '/objects/druid:bc123df4567',
                                        show_next: false, show_deposit: true))

      expect(page).to have_no_button('Next')
      expect(page).to have_button('Save as draft')
      expect(page).to have_css('button[type="submit"][form="tabbed_form"][name="commit"][value="deposit"]',
                               text: 'Deposit')
    end
  end
end
