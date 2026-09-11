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

  # Fills in the registration form with two items and submits it.
  def submit_two_items
    visit new_multiple_item_path

    expect(page).to have_css('h1', text: 'Register items')

    fill_in_registration_settings
    fill_in_two_items

    click_button 'Register items'
  end

  def fill_in_registration_settings
    select 'image', from: 'Content type'
    select apo_title, from: 'APO'
    select 'Stanford', from: 'View access'
    select 'Stanford', from: 'Download access'
  end

  def fill_in_two_items
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
  end

  # Waits for the validating page, which is shown while the form validation action is pending.
  # @return [FormValidationAction] the form validation action for the submitted form
  def wait_for_validating_page
    expect(page).to have_text('Validating...')

    FormValidationAction.last.tap do |form_validation_action|
      expect(page).to have_current_path(multiple_item_path(form_validation_action))
    end
  end

  context 'when the form validation is pending' do
    it 'shows the validating page and enqueues a validate form job' do
      submit_two_items

      form_validation_action = wait_for_validating_page

      expect(form_validation_action.user).to eq(user)
      expect(form_validation_action.status_queued?).to be true

      expect(ValidateFormJob).to have_been_enqueued.with(form_validation_action:)

      expect(BulkActions::RegisterFormJob).not_to have_been_enqueued
      expect(BulkAction.count).to eq(0)
    end
  end

  context 'when valid' do
    it 'enqueues a register form bulk action' do
      submit_two_items

      form_validation_action = wait_for_validating_page

      ValidateFormJob.perform_now(form_validation_action:)

      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last
      expect(page).to have_current_path(bulk_action_path(bulk_action))
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

    # Turbo renders a redirect's HTML before updating the URL to the redirect target, so the
    # scheduled-refresh controller on the bulk action page connects while the URL is still the
    # multiple items URL. Refreshes must keep working after that.
    it 'continues to refresh the bulk action page it redirects to' do
      submit_two_items

      form_validation_action = wait_for_validating_page

      ValidateFormJob.perform_now(form_validation_action:)

      expect(page).to have_toast("#{bulk_action_label} submitted")

      bulk_action = BulkAction.last
      expect(page).to have_current_path(bulk_action_path(bulk_action))
      expect(page).to have_text('Processing...')

      bulk_action.update!(status: :completed, druid_count_success: 2, druid_count_total: 2)

      # The page refreshes on an interval, so the completed bulk action is shown without reloading.
      expect(page).to have_css('table#bulk-action-details-table td', text: 'Completed')
      expect(page).to have_css('table#bulk-action-details-table td', text: '2 / 2 / 0')
      expect(page).to have_no_text('Processing...')
    end
  end

  context 'when invalid' do
    it 'shows a validation error and does not enqueue a bulk action' do
      visit new_multiple_item_path

      select apo_title, from: 'APO'
      # Leaving all of the item fields blank.

      click_button 'Register items'

      form_validation_action = wait_for_validating_page

      ValidateFormJob.perform_now(form_validation_action:)

      expect(page).to have_css('.invalid-feedback', text: 'at least one item is required')
      expect(page).to have_current_path(multiple_item_path(form_validation_action))

      expect(BulkActions::RegisterFormJob).not_to have_been_enqueued
      expect(BulkAction.count).to eq(0)
    end
  end

  context 'when failed' do
    it 'shows an error message and does not enqueue a bulk action' do
      submit_two_items

      form_validation_action = wait_for_validating_page

      form_validation_action.status_failed!

      expect(page).to have_css('.alert', text: 'An error occurred while validating your registrations. ' \
                                               'Please try again.')
      expect(page).to have_button('Register items')

      expect(BulkActions::RegisterFormJob).not_to have_been_enqueued
      expect(BulkAction.count).to eq(0)
    end
  end
end
