# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Item::ManageFilesStepFooterComponent, type: :component do
  let(:draft_actions_presenter) do
    version_service = instance_double(Sdr::VersionService, druid: 'druid:bc123df4567', open?: true, discardable?: true,
                                                           assembly_stopped_with_error?: false)
    DraftActionsPresenter.new(cocina_version: 2, version_service:)
  end
  let(:manage_files_flow) { Contents::ManageFilesFlow.new(content: build(:content, step:), agreement: false) }
  let(:step) { 'files' }
  let(:files_required) { false }

  before do
    render_inline(described_class.new(manage_files_flow:, form_id: 'item_form', druid: 'druid:bc123df4567',
                                      content_token: 'abc123', draft_actions_presenter:, files_required:))
  end

  it 'renders Previous and Next, which submit, and the save buttons disabled for unassociated files and uploading' do
    expect(page).to have_css('a[href="/contents/abc123/unsaved_changes"][data-turbo-method="delete"]' \
                             '[data-turbo-confirm="Discard unsaved changes to files?"]' \
                             '[data-disable-actions-target="disableable"]', text: 'Cancel')
    expect(page).to have_css('fieldset[data-disable-actions-target="disableable"] ' \
                             'button[form="item_form"][name="commit"][value="previous"]', text: 'Previous')
    expect(page).to have_css('fieldset[data-disable-actions-target="disableable"] ' \
                             'button[form="item_form"][name="commit"][value="next"]', text: 'Next')
    expect(page).to have_no_css('[data-files-required-target]')
    expect(page).to have_css('fieldset[data-disable-actions-target="disableable"] ' \
                             'button[form="item_form"][value="draft"][data-unassociated-files-target="submit"]')
    expect(page).to have_no_button('Deposit')
    expect(page).to have_link('Discard draft', href: '/objects/druid:bc123df4567/discard_draft')
  end

  context 'when files are required' do
    let(:files_required) { true }

    it 'renders Next disabled until there are files, with the reason' do
      expect(page).to have_css('button[value="next"][data-files-required-target="submit"]')
      expect(page).to have_css('[data-files-required-target="reason"]', text: 'Add at least one file to continue.')
    end
  end

  context 'when the first step' do
    let(:step) { 'details' }

    it 'does not render Previous' do
      expect(page).to have_no_button('Previous')
      expect(page).to have_button('Next')
    end
  end

  context 'when the last step' do
    let(:step) { 'deposit' }

    it 'renders Deposit instead of Next' do
      expect(page).to have_no_button('Next')
      expect(page).to have_css('button[form="item_form"][value="deposit"][data-unassociated-files-target="submit"]',
                               text: 'Deposit')
    end
  end
end
