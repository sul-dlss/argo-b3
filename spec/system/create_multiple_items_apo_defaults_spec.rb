# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Apply APO defaults when creating multiple items' do
  let(:workgroup) { 'sdr:test-workgroup' }
  let!(:user) { create(:user, groups: [workgroup]) }

  let(:apo_druid) { 'druid:bc123df4567' }
  let(:apo_title) { 'My APO' }
  let(:apo_cocina_object) do
    build(:admin_policy_with_metadata, id: apo_druid).new(
      administrative: {
        hasAdminPolicy: 'druid:hv992ry2431',
        hasAgreement: 'druid:hp308wm0436',
        accessTemplate: {
          view: 'location-based',
          download: 'location-based',
          location: 'm&m',
          copyright: 'Copyright © Stanford University.',
          license: 'https://creativecommons.org/licenses/by/4.0/legalcode'
        }
      }
    )
  end

  let(:other_apo_druid) { 'druid:xz987wv6543' }
  let(:other_apo_title) { 'Another APO' }
  let(:other_apo_cocina_object) do
    build(:admin_policy_with_metadata, id: other_apo_druid).new(
      administrative: {
        hasAdminPolicy: 'druid:hv992ry2431',
        hasAgreement: 'druid:hp308wm0436',
        accessTemplate: { view: 'stanford', download: 'none' }
      }
    )
  end

  before do
    sign_in user

    create(:permission, :edit, workgroup:, target_druid: apo_druid)
    create(:permission, :edit, workgroup:, target_druid: other_apo_druid)

    allow(Searchers::AdminPolicyList).to receive(:call).and_return([[other_apo_title, other_apo_druid],
                                                                    [apo_title, apo_druid]])
    cocina_objects = { apo_druid => apo_cocina_object, other_apo_druid => other_apo_cocina_object }
    allow(Sdr::Repository).to receive(:find) { |druid:| cocina_objects.fetch(druid) }
    allow(Searchers::TagSuggestions).to receive(:call).and_return([])
    allow(Sdr::Repository).to receive(:source_id_exists?).and_return(false)
    allow(CatalogRepository).to receive(:exists?).and_return(true)
  end

  context 'when the form is new' do
    it 'applies the defaults of the initially selected APO' do
      visit new_multiple_item_path

      expect(page).to have_select('APO', selected: other_apo_title)
      within('[data-apo-defaults-group="without_embargo"]') do
        expect(page).to have_select('View access', selected: 'Stanford')
        expect(page).to have_select('Download access', selected: 'None')
        expect(page).to have_css('.form-text', text: 'APO default = Stanford')
      end
      expect(page).to have_css('#items_registration_copyright_help', text: 'APO default = none')
    end
  end

  context 'when selecting an APO' do
    it 'sets the fields that the APO has defaults for and shows the defaults' do
      visit new_multiple_item_path
      expect(page).to have_css('#items_registration_copyright_help', text: 'APO default = none')

      fill_in 'Use and reproduction', with: 'Property rights reside with the repository.'
      fill_in 'Copyright', with: 'My copyright.'

      select apo_title, from: 'APO'

      expect(page).to have_field('Copyright', with: 'Copyright © Stanford University.')
      expect(page).to have_css('#items_registration_copyright_help',
                               text: 'APO default = Copyright © Stanford University.')
      # The APO has no default use and reproduction, so the entered one is cleared.
      expect(page).to have_field('Use and reproduction', with: '')
      expect(page).to have_select('License', selected: 'CC Attribution 4.0 International')
      expect(page).to have_css('#items_registration_license_help',
                               text: 'APO default = CC Attribution 4.0 International')
      within('[data-apo-defaults-group="without_embargo"]') do
        expect(page).to have_select('View access', selected: 'Location Based')
        expect(page).to have_select('Download access', selected: 'Location Based')
        expect(page).to have_select('Location', selected: 'Media and Microtext')
      end
    end
  end

  context 'when the form is redisplayed with errors' do
    it 'shows the defaults of the selected APO, keeping the entered values' do
      visit_and_enter_rights

      # Leaving the items blank.
      click_button 'Register items'
      ValidateFormJob.perform_now(form_validation_action: wait_for_validating_page)

      expect(page).to have_css('.invalid-feedback', text: 'at least one item is required')
      expect_entered_rights
    end
  end

  context 'when the form validation failed' do
    it 'shows the defaults of the selected APO, keeping the entered values' do
      visit_and_enter_rights

      click_button 'Register items'
      wait_for_validating_page.status_failed!

      expect(page).to have_css('.alert', text: 'An error occurred while validating your registrations.')
      expect_entered_rights
    end
  end

  context 'when clearing the items' do
    it 'shows the defaults of the selected APO, keeping the entered values' do
      visit_and_enter_rights
      choose 'Enter each item individually. Either FOLIO Instance HRID or Title is required.'
      within('#item-registrations') do
        # Leaving Title and FOLIO Instance HRID blank.
        fill_in 'Source ID', with: 'sul:first-item'
      end

      click_button 'Register items'
      ValidateFormJob.perform_now(form_validation_action: wait_for_validating_page)
      click_button 'Clear all items and enter again'

      expect(page).to have_no_button('Clear all items and enter again')
      expect_entered_rights
    end
  end

  # Selects the APO and enters rights that differ from its defaults.
  def visit_and_enter_rights
    visit new_multiple_item_path

    select apo_title, from: 'APO'
    expect(page).to have_field('Copyright', with: 'Copyright © Stanford University.')
    fill_in 'Copyright', with: 'My copyright.'
    within('[data-apo-defaults-group="without_embargo"]') do
      select 'World', from: 'View access'
    end
  end

  # The help texts show the defaults of the selected APO.
  def expect_entered_rights
    expect(page).to have_css('#items_registration_copyright_help',
                             text: 'APO default = Copyright © Stanford University.')
    expect(page).to have_field('Copyright', with: 'My copyright.')
    within('[data-apo-defaults-group="without_embargo"]') do
      expect(page).to have_css('.form-text', text: 'APO default = Location Based', count: 2)
      expect(page).to have_select('View access', selected: 'World')
    end
  end
end
