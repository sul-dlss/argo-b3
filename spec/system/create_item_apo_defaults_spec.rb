# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Apply APO defaults when creating an item' do
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
  end

  context 'when the form is new' do
    it 'applies the defaults of the initially selected APO' do
      visit_rights_tab

      expect(page).to have_select('APO', selected: other_apo_title)
      within('[data-apo-defaults-group="without_embargo"]') do
        expect(page).to have_select('View access', selected: 'Stanford')
        expect(page).to have_select('Download access', selected: 'None')
        expect(page).to have_css('.form-text', text: 'APO default = Stanford')
      end
      expect(page).to have_css('#item_copyright_help', text: 'APO default = none')
    end
  end

  context 'when the form is redisplayed with errors' do
    before do
      allow(Sdr::Repository).to receive(:source_id_exists?).and_return(false)
    end

    it 'shows the defaults of the selected APO, keeping the entered values' do
      visit_rights_tab

      select apo_title, from: 'APO'
      expect(page).to have_field('Copyright', with: 'Copyright © Stanford University.')
      fill_in 'Copyright', with: 'My copyright.'
      within('[data-apo-defaults-group="without_embargo"]') do
        select 'World', from: 'View access'
      end

      # Leaving Source ID and Title blank.
      find_by_id('deposit-tab').click
      click_button('Register only')
      expect(page).to have_css('.invalid-feedback', text: "can't be blank", visible: :all)

      find_by_id('rights-tab').click
      expect(page).to have_select('APO', selected: apo_title)
      expect(page).to have_field('Copyright', with: 'My copyright.')
      expect(page).to have_css('#item_copyright_help', text: 'APO default = Copyright © Stanford University.')
      within('[data-apo-defaults-group="without_embargo"]') do
        expect(page).to have_select('View access', selected: 'World')
        expect(page).to have_css('.form-text', text: 'APO default = Location Based', count: 2)
      end
    end
  end

  context 'without an embargo' do
    it 'sets the fields that the APO has defaults for and shows the defaults' do
      visit_rights_tab

      fill_in 'Use and reproduction', with: 'Property rights reside with the repository.'
      fill_in 'Copyright', with: 'My copyright.'
      select 'CC Zero 1.0', from: 'License'

      select apo_title, from: 'APO'

      # The APO default overwrites the entered copyright.
      expect(page).to have_field('Copyright', with: 'Copyright © Stanford University.')
      expect(page).to have_css('.form-text', text: 'APO default = Copyright © Stanford University.')
      # The APO has no default use and reproduction, so the entered one is cleared.
      expect(page).to have_field('Use and reproduction', with: '')
      expect(page).to have_css('#item_use_and_reproduction_statement_help', text: 'APO default = none')
      expect(page).to have_select('License', selected: 'CC Attribution 4.0 International')
      expect(page).to have_css('#item_license_help', text: 'APO default = CC Attribution 4.0 International')

      within('[data-apo-defaults-group="without_embargo"]') do
        expect(page).to have_select('View access', selected: 'Location Based')
        expect(page).to have_select('Download access', selected: 'Location Based')
        expect(page).to have_select('Location', selected: 'Media and Microtext')
        expect(page).to have_css('.form-text', text: 'APO default = Location Based', count: 2)
        expect(page).to have_css('.form-text', text: 'APO default = Media and Microtext')
      end
      expect(Sdr::Repository).to have_received(:find).with(druid: apo_druid)
    end
  end

  context 'when changing to an APO without defaults' do
    it 'replaces the previous APO defaults, clearing the fields that the APO has no defaults for' do
      visit_rights_tab

      select apo_title, from: 'APO'
      expect(page).to have_field('Copyright', with: 'Copyright © Stanford University.')
      within('[data-apo-defaults-group="without_embargo"]') do
        expect(page).to have_select('Location', selected: 'Media and Microtext')
      end
      fill_in 'Copyright', with: 'My copyright.'
      fill_in 'Use and reproduction', with: 'Property rights reside with the repository.'

      select other_apo_title, from: 'APO'

      expect(page).to have_field('Copyright', with: '')
      expect(page).to have_css('#item_copyright_help', text: 'APO default = none')
      expect(page).to have_field('Use and reproduction', with: '')
      expect(page).to have_select('License', selected: '')
      expect(page).to have_css('#item_license_help', text: 'APO default = none')
      within('[data-apo-defaults-group="without_embargo"]') do
        expect(page).to have_select('View access', selected: 'Stanford')
        expect(page).to have_select('Download access', selected: 'None')
        expect(page).to have_css('.form-text', text: 'APO default = Stanford')
        # The location of the previously selected APO is cleared. It is disabled, since access is not location-based.
        expect(page).to have_field('Location', with: '', disabled: true)
        expect(page).to have_css('.form-text', text: 'APO default = none')
      end
    end
  end

  context 'when the APO license is not a license option' do
    let(:other_apo_cocina_object) do
      build(:admin_policy_with_metadata, id: other_apo_druid).new(
        administrative: {
          hasAdminPolicy: 'druid:hv992ry2431',
          hasAgreement: 'druid:hp308wm0436',
          accessTemplate: { view: 'world', download: 'world',
                            license: 'https://cocina.sul.stanford.edu/licenses/none' }
        }
      )
    end

    it 'clears the license and shows the APO license in the help text' do
      visit_rights_tab

      select apo_title, from: 'APO'
      expect(page).to have_select('License', selected: 'CC Attribution 4.0 International')

      select other_apo_title, from: 'APO'

      expect(page).to have_select('License', selected: '')
      expect(page).to have_css('#item_license_help', text: 'APO default = https://cocina.sul.stanford.edu/licenses/none')
    end
  end

  context 'with an embargo' do
    it 'sets only the access once the embargo ends' do
      visit_rights_tab
      choose 'With embargo', allow_label_click: true

      select apo_title, from: 'APO'

      within('[data-apo-defaults-group="embargo_ends"]') do
        expect(page).to have_select('View access', selected: 'Location Based')
        expect(page).to have_select('Download access', selected: 'Location Based')
        expect(page).to have_select('Location', selected: 'Media and Microtext')
        expect(page).to have_css('.form-text', text: 'APO default = Media and Microtext')
      end
      within(:fieldset, 'Access settings during embargo') do
        expect(page).to have_select('View access', selected: 'World')
        expect(page).to have_select('Download access', selected: 'World')
        expect(page).to have_no_text('APO default')
      end
    end
  end

  context 'when choosing an embargo after selecting the APO' do
    it 'sets the access once the embargo ends' do
      visit_rights_tab
      select apo_title, from: 'APO'
      within('[data-apo-defaults-group="without_embargo"]') do
        expect(page).to have_select('View access', selected: 'Location Based')
      end

      choose 'With embargo', allow_label_click: true

      within('[data-apo-defaults-group="embargo_ends"]') do
        expect(page).to have_select('View access', selected: 'Location Based')
        expect(page).to have_select('Download access', selected: 'Location Based')
        expect(page).to have_select('Location', selected: 'Media and Microtext')
      end
    end
  end

  def visit_rights_tab
    visit new_item_path
    find_by_id('rights-tab').click
    expect(page).to have_css('#rights-tab.active')
  end
end
