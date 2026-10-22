# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin object permissions' do
  let(:druid) { 'druid:bc123df4567' }
  let(:admin_user) { create(:user, groups: [AuthenticationHelpers::ADMIN_GROUP]) }

  before do
    create(:permission, :edit, workgroup: 'sdr:existing', target_druid: druid)
    allow(Sdr::Repository).to receive(:find_solr).and_return(
      Search::Fields::ID => druid, Search::Fields::TITLE => 'My APO', Search::Fields::OBJECT_TYPES => ['APO']
    )
    allow(Sdr::Event).to receive(:create)
    sign_in(admin_user)
  end

  it 'adds a permission for a new workgroup and deletes a permission' do
    visit admin_object_permissions_path(druid)
    expect(page).to have_css('h1', text: 'Edit APO permissions')

    # Enter a workgroup that does not yet have any permissions.
    find('.ts-control input').set('sdr:newgroup')
    find('.ts-dropdown .create', text: 'sdr:newgroup').click
    choose 'Edit'
    click_button 'Add'

    expect(page).to have_toast('Permission added')
    expect(page).to have_css('#object-permissions tbody tr', count: 2)
    within('#object-permissions tbody tr', text: 'sdr:newgroup') do
      expect(page).to have_css('td', exact_text: 'Edit')
    end
    # The form is reset, with the new workgroup available as an option.
    expect(page).to have_checked_field('Read')
    expect(page).to have_select('admin_object_permission[workgroup]', visible: :all,
                                                                      selected: 'Select or enter a workgroup',
                                                                      with_options: ['sdr:newgroup'])

    click_button 'Delete Edit permission for sdr:existing'

    expect(page).to have_toast('Permission deleted')
    expect(page).to have_css('#object-permissions tbody tr', count: 1)
    expect(page).to have_no_css('#object-permissions td', exact_text: 'sdr:existing')
  end

  it 'shows an error when adding a permission that the workgroup already has' do
    visit admin_object_permissions_path(druid)

    find('.ts-control input').set('sdr:existing')
    find('.ts-dropdown .option', text: 'sdr:existing', exact_text: true).click
    choose 'Edit'
    click_button 'Add'

    expect(page).to have_css('.invalid-feedback', text: 'already has this permission')
    expect(page).not_to have_toast('Permission added')
    expect(page).to have_css('#object-permissions tbody tr', count: 1)
  end
end
