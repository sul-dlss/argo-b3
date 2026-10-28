# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Item::ManageFilesTabFooterComponent, type: :component do
  let(:pane) { SdrViewComponents::TabForm::PaneComponent.new(tab_name: :deposit, label: 'Deposit') }

  it 'renders the footer with buttons disabled for unassociated files and while uploading' do
    render_inline(described_class.new(pane:, form_id: 'item_form', druid: 'druid:bc123df4567',
                                      discard_or_purge_action: :discard_draft, show_next: false, show_deposit: true))

    expect(page).to have_link('Cancel', href: '/objects/druid:bc123df4567')
    expect(page).to have_button('Previous')
    expect(page).to have_no_button('Next')
    expect(page).to have_css('fieldset[data-disable-actions-target="disableable"] ' \
                             'button[form="item_form"][value="draft"][data-unassociated-files-target="submit"]')
    expect(page).to have_css('fieldset[data-disable-actions-target="disableable"] ' \
                             'button[form="item_form"][value="deposit"][data-unassociated-files-target="submit"]')
    expect(page).to have_css('a[href="/objects/druid:bc123df4567/discard_draft"]' \
                             '[data-disable-actions-target="disableable"]', text: 'Discard draft')
  end
end
