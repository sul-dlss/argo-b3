# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Item::ManageFilesTabFooterComponent, type: :component do
  let(:pane) { SdrViewComponents::TabForm::PaneComponent.new(tab_name: :deposit, label: 'Deposit') }
  let(:draft_actions_presenter) do
    version_service = instance_double(Sdr::VersionService, druid: 'druid:bc123df4567', open?: true, discardable?: true,
                                                           assembly_stopped_with_error?: false)
    DraftActionsPresenter.new(cocina_version: 2, version_service:)
  end

  it 'renders the footer with buttons disabled for unassociated files and while uploading' do
    render_inline(described_class.new(pane:, form_id: 'item_form', druid: 'druid:bc123df4567',
                                      content_token: 'abc123', draft_actions_presenter:, show_next: false,
                                      show_deposit: true))

    expect(page).to have_css('a[href="/contents/abc123/unsaved_changes"][data-turbo-method="delete"]' \
                             '[data-turbo-confirm="Discard unsaved changes to files?"]' \
                             '[data-disable-actions-target="disableable"]', text: 'Cancel')
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
