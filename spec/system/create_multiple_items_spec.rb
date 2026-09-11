# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create multiple items' do
  let(:workgroup) { 'sdr:test-workgroup' }
  let!(:user) { create(:user, groups: [workgroup]) }

  let(:apo_druid) { generate(:unique_druid) }
  let(:apo_title) { 'My APO' }

  let(:bulk_action_label) { BulkActions::REGISTER_FORM.label }

  before do
    sign_in user

    create(:permission, :edit, workgroup:, target_druid: apo_druid)

    allow(Searchers::AdminPolicyList).to receive(:call).and_return([[apo_title, apo_druid]])
  end

  context 'when valid' do
    it 'enqueues a register form bulk action' do
      visit new_multiple_item_path

      expect(page).to have_css('h1', text: 'Register items')

      select 'image', from: 'Content type'
      select apo_title, from: 'APO'
      select 'Stanford', from: 'View access'
      select 'Stanford', from: 'Download access'

      within(first('.form-instance')) do
        fill_in 'Source ID', with: 'sul:first-item'
        fill_in 'Title', with: 'First title'
      end

      click_button 'Add another item'
      expect(page).to have_css('.form-instance', count: 2)

      within(all('.form-instance').last) do
        fill_in 'Source ID', with: 'sul:second-item'
        fill_in 'Folio instance HRID', with: 'in11403803'
        fill_in 'Barcode', with: '36105212345678'
      end

      click_button 'Register items'

      expect(page).to have_current_path(bulk_actions_path)
      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last
      expect(bulk_action.action_type).to eq(BulkActions::REGISTER_FORM.action_type.to_s)
      expect(bulk_action.user).to eq(user)
      expect(bulk_action.queued?).to be true

      expect(BulkActions::RegisterFormJob).to have_been_enqueued.with(
        bulk_action:,
        items_registration_form: an_object_having_attributes(
          content_type: Cocina::Models::ObjectType.image,
          apo_druid:,
          access_view: 'stanford',
          access_download: 'stanford'
        )
      )

      expect(BulkActions::RegisterFormJob).to have_been_enqueued.with(
        bulk_action:,
        items_registration_form: satisfy do |items_registration_form|
          item_registrations = items_registration_form.item_registrations.to_a
          expect(item_registrations.map(&:source_id)).to eq(['sul:first-item', 'sul:second-item'])
          expect(item_registrations.first.title).to eq('First title')
          expect(item_registrations.last.catalog_record_id).to eq('in11403803')
          expect(item_registrations.last.barcode).to eq('36105212345678')
        end
      )
    end
  end

  context 'when invalid' do
    it 'shows a validation error and does not enqueue a bulk action' do
      visit new_multiple_item_path

      select apo_title, from: 'APO'
      # Leaving all of the item fields blank.

      click_button 'Register items'

      expect(page).to have_css('.invalid-feedback', text: 'at least one item is required')

      expect(BulkActions::RegisterFormJob).not_to have_been_enqueued
      expect(BulkAction.count).to eq(0)
    end
  end
end
