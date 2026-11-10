# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Item::TabNavigationComponent, type: :component do
  let(:pane) { SdrViewComponents::TabForm::PaneComponent.new(tab_name: :details, label: 'Details') }

  it 'renders the cancel, previous, and next buttons with a decorative next icon' do
    render_inline(described_class.new(pane:, cancel_path: '/objects/druid:bc123df4567'))

    expect(page).to have_link('Cancel', href: '/objects/druid:bc123df4567')
    expect(page).to have_button('Previous')
    expect(page).to have_button('Next')
    expect(page).to have_css('button i.bi-arrow-right[aria-hidden="true"]')
  end

  context 'without previous and next' do
    it 'renders only the cancel button' do
      render_inline(described_class.new(pane:, cancel_path: '/objects/druid:bc123df4567',
                                        show_next: false, show_previous: false))

      expect(page).to have_link('Cancel')
      expect(page).to have_no_button
    end
  end
end
