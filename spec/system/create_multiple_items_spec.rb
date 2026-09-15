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

  # The container for the item registrations. Item rows are scoped to it since the tag rows on the
  # page are also rendered as .form-instance rows.
  def item_registrations
    find_by_id('item-registrations')
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

    # No license is selected by default.
    expect(page).to have_select('License', selected: '')

    fill_in 'Use and reproduction', with: 'Property rights reside with the repository.'
    fill_in 'Copyright', with: 'Copyright © Stanford University.'
    select 'CC Zero 1.0', from: 'License'
  end

  def fill_in_two_items
    choose 'Enter each item individually. Either FOLIO Instance HRID or Title is required.'

    within(item_registrations) do
      within(first('.form-instance')) do
        fill_in 'Source ID', with: 'sul:first-item'
        fill_in 'Title', with: 'First title'
      end

      add_item_row

      within(all('.form-instance').last) do
        fill_in 'Source ID', with: 'sul:second-item'
        fill_in 'Folio instance HRID', with: 'in11403803'
        fill_in 'Barcode', with: '36105212345678'
      end
    end
  end

  # Adds a second item row. Must be called within the item registrations container.
  def add_item_row
    click_button 'Add another item'
    expect(page).to have_css('.form-instance', count: 2)
  end

  def fill_in_tags
    fill_in 'items_registration[other_tags_attributes][0][tag]', with: 'Registered By : mjgiarlo'
    click_button 'Add another tag'
    fill_in 'items_registration[other_tags_attributes][1][tag]', with: 'Remediated By : 5.0.0'
    fill_in 'items_registration[project_tags_attributes][0][tag]', with: 'Argo'
    fill_in 'items_registration[ticket_tags_attributes][0][tag]', with: 'ABC-123'
  end

  # Fills in the registration form with a valid item and an item missing a title, then submits it.
  def submit_valid_and_invalid_item
    visit new_multiple_item_path

    expect(page).to have_css('h1', text: 'Register items')

    fill_in_registration_settings
    fill_in_valid_and_invalid_item

    click_button 'Register items'
  end

  def fill_in_valid_and_invalid_item
    choose 'Enter each item individually. Either FOLIO Instance HRID or Title is required.'

    within(item_registrations) do
      within(first('.form-instance')) do
        fill_in 'Source ID', with: 'sul:first-item'
        fill_in 'Title', with: 'First title'
      end

      add_item_row

      within(all('.form-instance').last) do
        # Leaving Title and Folio instance HRID blank.
        fill_in 'Source ID', with: 'sul:second-item'
      end
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
          access_download: 'stanford',
          use_and_reproduction_statement: 'Property rights reside with the repository.',
          copyright: 'Copyright © Stanford University.',
          license: 'https://creativecommons.org/publicdomain/zero/1.0/legalcode'
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

  context 'when no license or rights statements are provided' do
    it 'enqueues a register form bulk action without a license or rights statements' do
      visit new_multiple_item_path

      select 'image', from: 'Content type'
      select apo_title, from: 'APO'
      select 'Stanford', from: 'View access'
      select 'Stanford', from: 'Download access'
      # Leaving Use and reproduction, Copyright, and License blank.

      fill_in_two_items

      click_button 'Register items'

      form_validation_action = wait_for_validating_page

      ValidateFormJob.perform_now(form_validation_action:)

      expect(page).to have_toast("#{bulk_action_label} submitted")

      expect(BulkActions::RegisterFormJob).to have_been_enqueued.with(
        bulk_action: BulkAction.last,
        items_registration_form: an_object_having_attributes(
          use_and_reproduction_statement: be_blank,
          copyright: be_blank,
          license: be_blank
        )
      )
    end
  end

  context 'when invalid' do
    it 'shows a validation error and does not enqueue a bulk action' do
      visit new_multiple_item_path

      select apo_title, from: 'APO'
      choose 'Enter each item individually. Either FOLIO Instance HRID or Title is required.'
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

  context 'when tags are provided' do
    it 'enqueues a register form bulk action with the tags' do
      visit new_multiple_item_path

      expect(page).to have_css('h1', text: 'Register items')

      fill_in_registration_settings
      fill_in_tags
      fill_in_two_items

      click_button 'Register items'

      form_validation_action = wait_for_validating_page

      ValidateFormJob.perform_now(form_validation_action:)

      expect(page).to have_toast("#{bulk_action_label} submitted")

      expect(BulkActions::RegisterFormJob).to have_been_enqueued.with(
        bulk_action: BulkAction.last,
        items_registration_form: an_object_having_attributes(
          tags: ['Registered By : mjgiarlo', 'Remediated By : 5.0.0', 'Project : Argo', 'Ticket : ABC-123']
        )
      )
    end
  end

  context 'when an other tag is malformed' do
    it 'shows a validation error, retains the tag, and does not enqueue a bulk action' do
      visit new_multiple_item_path

      expect(page).to have_css('h1', text: 'Register items')

      fill_in_registration_settings
      fill_in 'items_registration[other_tags_attributes][0][tag]', with: 'Registered By'
      fill_in_two_items

      click_button 'Register items'

      form_validation_action = wait_for_validating_page

      ValidateFormJob.perform_now(form_validation_action:)

      expect(page).to have_css('.invalid-feedback',
                               text: 'must be a series of 2 or more strings delimited with space-padded colons')
      expect(page).to have_field('items_registration[other_tags_attributes][0][tag]', with: 'Registered By')

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

  context 'when there are item errors' do
    it 'shows only the items with errors and allows clearing all items' do
      submit_valid_and_invalid_item

      form_validation_action = wait_for_validating_page

      ValidateFormJob.perform_now(form_validation_action:)

      expect(page).to have_css('.alert-danger',
                               text: 'Fix the errors or delete items below and click "Register items" again, ' \
                                     'or click "Clear all items and enter again."')

      # Only the item with errors is displayed.
      expect(item_registrations).to have_css('.form-instance', count: 1)
      expect(page).to have_field('Source ID', with: 'sul:second-item')
      expect(page).to have_css('.invalid-feedback', text: 'title is required if a FOLIO Instance HRID is not provided')

      # The item without errors is retained as hidden fields.
      expect(page).to have_field(with: 'sul:first-item', type: 'hidden', visible: :hidden)
      expect(page).to have_field(with: 'First title', type: 'hidden', visible: :hidden)

      expect(page).to have_no_text('Enter each item individually')

      click_button 'Clear all items and enter again'

      expect(page).to have_text('Enter each item individually')
      expect(page).to have_no_button('Clear all items and enter again')
      expect(item_registrations).to have_css('.form-instance', count: 1)
      expect(page).to have_field('Source ID', with: '')
      expect(page).to have_no_field(with: 'sul:first-item', type: 'hidden', visible: :hidden)
    end
  end

  context 'when there are no item errors' do
    it 'does not show the clear all items button' do
      visit new_multiple_item_path

      expect(page).to have_button('Register items')
      expect(page).to have_no_button('Clear all items and enter again')
    end
  end

  context 'when entering a tab-delimited list of items' do
    it 'enqueues a register form bulk action with an item per row' do
      visit new_multiple_item_path

      expect(page).to have_css('h1', text: 'Register items')

      fill_in_registration_settings

      choose 'Enter a tab-delimited list of Barcode, FOLIO Instance HRID, Source ID, and Title'
      fill_in 'Enter tab-delimited list',
              with: "36105212345678\tin11403803\tsul:first-item\tFirst title\n" \
                    "36105287654321\tin11403804\tsul:second-item\tSecond title"

      click_button 'Register items'

      form_validation_action = wait_for_validating_page

      ValidateFormJob.perform_now(form_validation_action:)

      expect(page).to have_toast("#{bulk_action_label} submitted")
      expect(page).to have_current_path(bulk_action_path(BulkAction.last))

      expect(BulkActions::RegisterFormJob).to have_been_enqueued.with(
        bulk_action: BulkAction.last,
        items_registration_form: satisfy do |items_registration_form|
          item_registrations = items_registration_form.item_registrations.to_a
          expect(item_registrations.map(&:barcode)).to eq(%w[36105212345678 36105287654321])
          expect(item_registrations.map(&:catalog_record_id)).to eq(%w[in11403803 in11403804])
          expect(item_registrations.map(&:source_id)).to eq(['sul:first-item', 'sul:second-item'])
          expect(item_registrations.map(&:title)).to eq(['First title', 'Second title'])
        end
      )
    end
  end

  context 'when the tab-delimited list is blank' do
    it 'shows the presence error for the text area and does not enqueue a bulk action' do
      visit new_multiple_item_path

      fill_in_registration_settings

      choose 'Enter a tab-delimited list of Barcode, FOLIO Instance HRID, Source ID, and Title'
      # Leaving the tab-delimited list blank.

      click_button 'Register items'

      form_validation_action = wait_for_validating_page

      ValidateFormJob.perform_now(form_validation_action:)

      expect(page).to have_css('.invalid-feedback', text: 'at least one item is required')
      expect(page).to have_current_path(multiple_item_path(form_validation_action))

      expect(BulkActions::RegisterFormJob).not_to have_been_enqueued
      expect(BulkAction.count).to eq(0)
    end
  end

  context 'when uploading a CSV of items' do
    it 'enqueues a register form bulk action with an item per row' do
      visit new_multiple_item_path

      expect(page).to have_css('h1', text: 'Register items')

      fill_in_registration_settings

      choose 'Upload CSV from computer'
      attach_file 'Upload a CSV file', file_fixture('register_multiple_items.csv')

      click_button 'Register items'

      form_validation_action = wait_for_validating_page

      ValidateFormJob.perform_now(form_validation_action:)

      expect(page).to have_toast("#{bulk_action_label} submitted")
      expect(page).to have_current_path(bulk_action_path(BulkAction.last))

      expect(BulkActions::RegisterFormJob).to have_been_enqueued.with(
        bulk_action: BulkAction.last,
        items_registration_form: satisfy do |items_registration_form|
          item_registrations = items_registration_form.item_registrations.to_a
          expect(item_registrations.map(&:barcode)).to eq(%w[36105212345678 36105287654321])
          expect(item_registrations.map(&:catalog_record_id)).to eq(%w[in11403803 in11403804])
          expect(item_registrations.map(&:source_id)).to eq(['sul:first-item', 'sul:second-item'])
          expect(item_registrations.map(&:title)).to eq(['First title', 'Second title'])
        end
      )
    end

    context 'when the CSV has no rows' do
      it 'shows the presence error for the file field and does not enqueue a bulk action' do
        visit new_multiple_item_path

        fill_in_registration_settings

        choose 'Upload CSV from computer'
        attach_file 'Upload a CSV file', file_fixture('register_multiple_items_no_items.csv')

        click_button 'Register items'

        form_validation_action = wait_for_validating_page

        ValidateFormJob.perform_now(form_validation_action:)

        expect(page).to have_css('.invalid-feedback', text: 'at least one item is required')
        expect(page).to have_current_path(multiple_item_path(form_validation_action))

        expect(BulkActions::RegisterFormJob).not_to have_been_enqueued
        expect(BulkAction.count).to eq(0)
      end
    end

    context 'when the CSV is missing the source_id column' do
      it 'shows a validation error for the file field and does not enqueue a bulk action' do
        visit new_multiple_item_path

        fill_in_registration_settings

        choose 'Upload CSV from computer'
        attach_file 'Upload a CSV file', file_fixture('register_multiple_items_bad.csv')

        click_button 'Register items'

        form_validation_action = wait_for_validating_page

        ValidateFormJob.perform_now(form_validation_action:)

        expect(page).to have_css('.invalid-feedback', text: 'missing headers: source_id.')
        expect(page).to have_current_path(multiple_item_path(form_validation_action))

        expect(BulkActions::RegisterFormJob).not_to have_been_enqueued
        expect(BulkAction.count).to eq(0)
      end
    end
  end
end
