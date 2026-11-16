# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Item::EditTabFooterComponent, type: :component do
  let(:pane) { SdrViewComponents::TabForm::PaneComponent.new(tab_name: :deposit, label: 'Deposit') }
  let(:draft_actions_presenter) do
    version_service = instance_double(Sdr::VersionService, druid: 'druid:bc123df4567', open?: true, discardable?: true,
                                                           assembly_stopped_with_error?: assembly_stopped_with_error)
    DraftActionsPresenter.new(cocina_version: 2, version_service:)
  end
  let(:assembly_stopped_with_error) { false }

  context 'without deposit' do
    it 'renders the navigation and the save as draft button' do
      render_inline(described_class.new(pane:, form_id: 'tabbed_form', cancel_path: '/objects/druid:bc123df4567',
                                        druid: 'druid:bc123df4567', draft_actions_presenter:))

      expect(page).to have_link('Cancel', href: '/objects/druid:bc123df4567')
      expect(page).to have_button('Previous')
      expect(page).to have_button('Next')
      expect(page).to have_css('button i.bi-arrow-right[aria-hidden="true"]')
      expect(page).to have_css('button[type="submit"][form="tabbed_form"][name="commit"][value="draft"]',
                               text: 'Save as draft')
      expect(page).to have_css('a[href="/objects/druid:bc123df4567/discard_draft"][data-turbo-method="delete"]' \
                               '[data-turbo-confirm^="Discard this draft?"]', text: 'Discard draft')
      expect(page).to have_no_button('Deposit')
      expect(page).to have_no_button('Save draft and edit files')
    end
  end

  context 'with edit files and deposit' do
    it 'renders the save draft and edit files, save as draft, and deposit buttons' do
      render_inline(described_class.new(pane:, form_id: 'tabbed_form', cancel_path: '/objects/druid:bc123df4567',
                                        druid: 'druid:bc123df4567', draft_actions_presenter:,
                                        show_next: false, show_edit_files: true, show_deposit: true))

      expect(page).to have_no_button('Next')
      expect(page).to have_css('button[type="submit"][form="tabbed_form"][name="commit"][value="add_files"]',
                               text: 'Save draft and edit files')
      expect(page).to have_button('Save as draft')
      expect(page).to have_css('button[type="submit"][form="tabbed_form"][name="commit"][value="deposit"]',
                               text: 'Deposit')
      # Deposit is next to Previous, before the right-aligned draft buttons.
      expect(page.all('button').map { |button| button.text.strip })
        .to eq(['Previous', 'Deposit', 'Save draft and edit files', 'Save as draft'])
    end
  end

  context 'with deposit when depositing is stopped' do
    let(:assembly_stopped_with_error) { true }

    it 'renders the save as draft button without the deposit button' do
      render_inline(described_class.new(pane:, form_id: 'tabbed_form', cancel_path: '/objects/druid:bc123df4567',
                                        druid: 'druid:bc123df4567', draft_actions_presenter:,
                                        show_next: false, show_deposit: true))

      expect(page).to have_button('Save as draft')
      expect(page).to have_no_button('Deposit')
    end
  end

  context 'with submit and actions data' do
    it 'renders the data on the submit buttons, the actions fieldset, and the discard draft link' do
      render_inline(described_class.new(pane:, form_id: 'item_form', cancel_path: '/objects/druid:bc123df4567',
                                        druid: 'druid:bc123df4567', draft_actions_presenter:,
                                        show_next: false, show_deposit: true,
                                        submit_data: { unassociated_files_target: 'submit' },
                                        actions_data: { disable_actions_target: 'disableable' }))

      expect(page).to have_css('fieldset[data-disable-actions-target="disableable"] ' \
                               'button[value="draft"][data-unassociated-files-target="submit"]')
      expect(page).to have_css('fieldset[data-disable-actions-target="disableable"] ' \
                               'button[value="deposit"][data-unassociated-files-target="submit"]')
      expect(page).to have_css('a[data-disable-actions-target="disableable"][data-turbo-method="delete"]',
                               text: 'Discard draft')
    end
  end

  context 'with navigation' do
    it 'renders the navigation instead of the tab navigation' do
      render_inline(described_class.new(form_id: 'item_form', cancel_path: '/objects/druid:bc123df4567',
                                        druid: 'druid:bc123df4567', draft_actions_presenter:)) do |component|
        component.with_navigation { '<button>Step navigation</button>'.html_safe }
      end

      expect(page).to have_button('Step navigation')
      expect(page).to have_no_link('Cancel')
      expect(page).to have_button('Save as draft')
    end
  end
end
