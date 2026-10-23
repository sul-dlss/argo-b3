# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Apply APO defaults when editing an item' do
  let(:druid) { 'druid:bc123df4567' }
  let(:access) do
    { view: 'world', download: 'world', copyright: 'My copyright.',
      useAndReproductionStatement: 'My use and reproduction statement.',
      license: 'https://creativecommons.org/publicdomain/zero/1.0/legalcode' }
  end
  let(:cocina_object) { build(:dro_with_metadata, id: druid, admin_policy_id: apo_druid).new(access:) }
  let!(:user) { create(:user) }

  let(:apo_druid) { 'druid:dm456gh7890' }
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
    create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)

    sign_in(user)

    allow(Searchers::AdminPolicyList).to receive(:call).and_return([[apo_title, apo_druid],
                                                                    [other_apo_title, other_apo_druid]])
    allow(Searchers::CollectionListByDruid).to receive(:call).and_return([])
    allow(Sdr::VersionService).to receive(:new)
      .and_return(version_service_double(open?: true, version_description: 'Fixing the rights'))
    cocina_objects = { druid => cocina_object, apo_druid => apo_cocina_object,
                       other_apo_druid => other_apo_cocina_object }
    allow(Sdr::Repository).to receive(:find) { |druid:| cocina_objects.fetch(druid) }
  end

  context 'without an embargo' do
    it 'shows the APO defaults, applying them only when the button is clicked' do
      visit_rights_tab

      # The item's rights are kept when the form is shown.
      expect(page).to have_select('APO', selected: apo_title)
      expect(page).to have_css('#item_copyright_help', text: 'APO default = Copyright © Stanford University.')
      expect(page).to have_field('Copyright', with: 'My copyright.')
      expect(page).to have_field('Use and reproduction', with: 'My use and reproduction statement.')
      expect(page).to have_select('License', selected: 'CC Zero 1.0')
      within('[data-apo-defaults-group="without_embargo"]') do
        expect(page).to have_select('View access', selected: 'World')
        expect(page).to have_select('Download access', selected: 'World')
        expect(page).to have_css('.form-text', text: 'APO default = Location Based', count: 2)
      end

      click_button 'Apply APO defaults'

      expect(page).to have_field('Copyright', with: 'Copyright © Stanford University.')
      # The APO has no default use and reproduction, so the item's is cleared.
      expect(page).to have_field('Use and reproduction', with: '')
      expect(page).to have_select('License', selected: 'CC Attribution 4.0 International')
      within('[data-apo-defaults-group="without_embargo"]') do
        expect(page).to have_select('View access', selected: 'Location Based')
        expect(page).to have_select('Download access', selected: 'Location Based')
        expect(page).to have_select('Location', selected: 'Media and Microtext')
      end
    end
  end

  context 'when selecting another APO' do
    it 'shows the selected APO defaults, applying them when the button is clicked' do
      visit_rights_tab
      expect(page).to have_css('#item_copyright_help', text: 'APO default = Copyright © Stanford University.')

      select other_apo_title, from: 'APO'

      expect(page).to have_css('#item_copyright_help', text: 'APO default = none')
      expect(page).to have_css('#item_license_help', text: 'APO default = none')
      expect(page).to have_field('Copyright', with: 'My copyright.')
      expect(page).to have_select('License', selected: 'CC Zero 1.0')
      within('[data-apo-defaults-group="without_embargo"]') do
        expect(page).to have_select('View access', selected: 'World')
        expect(page).to have_css('.form-text', text: 'APO default = Stanford')
      end

      click_button 'Apply APO defaults'

      expect(page).to have_field('Copyright', with: '')
      expect(page).to have_select('License', selected: '')
      within('[data-apo-defaults-group="without_embargo"]') do
        expect(page).to have_select('View access', selected: 'Stanford')
        expect(page).to have_select('Download access', selected: 'None')
      end
    end
  end

  context 'with an embargo' do
    let(:release_date) { (DateTime.now + 1.year).strftime('%Y-01-01') }
    let(:access) do
      { view: 'stanford', download: 'stanford',
        embargo: { releaseDate: release_date, view: 'world', download: 'world' } }
    end

    it 'applies the APO defaults to the access once the embargo ends' do
      visit_rights_tab
      expect(page).to have_field('With embargo', type: 'radio', checked: true, visible: :all)
      within('[data-apo-defaults-group="embargo_ends"]') do
        expect(page).to have_select('View access', selected: 'World')
        expect(page).to have_css('.form-text', text: 'APO default = Media and Microtext')
      end

      click_button 'Apply APO defaults'

      within('[data-apo-defaults-group="embargo_ends"]') do
        expect(page).to have_select('View access', selected: 'Location Based')
        expect(page).to have_select('Download access', selected: 'Location Based')
        expect(page).to have_select('Location', selected: 'Media and Microtext')
      end
      within(:fieldset, 'Access settings during embargo') do
        expect(page).to have_select('View access', selected: 'Stanford')
        expect(page).to have_select('Download access', selected: 'Stanford')
      end
    end
  end

  def visit_rights_tab
    visit edit_item_path(druid)
    click_button 'APO, collection, rights'
    expect(page).to have_css('#rights-tab.active')
  end
end
