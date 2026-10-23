# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin object permissions' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:user) { create(:user, groups: [AuthenticationHelpers::ADMIN_GROUP]) }
  let(:cocina_object) { build(:collection_with_metadata, id: druid) }

  before do
    create(:permission, :read_unrestricted, workgroup: 'sdr:curators')
    allow(Sdr::Repository).to receive_messages(
      find: cocina_object,
      find_solr: {
        Search::Fields::ID => druid, Search::Fields::OBJECT_TYPES => ['collection'],
        Search::Fields::TITLE => 'My collection',
        Search::Fields::APO_DRUID => ['druid:df456gh7890'], Search::Fields::APO_TITLE => ['My APO']
      }
    )
    allow(Sdr::WorkflowService).to receive_messages(published?: false, workflows_for: [])
    allow(Searchers::CollectionItemCount).to receive(:call).and_return(0)
    allow(Sdr::Event).to receive(:create)
    sign_in(user)
  end

  it 'adds Read and Edit permissions immediately and deletes them with table refreshes and toasts' do
    visit object_path(druid)
    within('.object-show') { click_button 'Manage permissions' }
    expect(page).to have_current_path(admin_object_permissions_path(druid))

    choose 'Read'
    find('.ts-control input').set('sdr:curators')
    find('.ts-dropdown .option', text: 'sdr:curators', exact_text: true).click
    click_button 'Add permission'

    expect(page).to have_toast('Permission added')
    expect(page).to have_css('#object-permissions-table tbody tr', text: 'sdr:curators Read')
    expect(page).to have_no_text('No permissions.')
    find('h1', text: 'Manage permissions').click
    expect(page).to have_no_css('.ts-dropdown', visible: :visible)

    choose 'Edit'
    find('.ts-control').click
    find('.ts-control input').set('sdr:new-curators')
    find('.ts-dropdown .create', text: 'sdr:new-curators').click
    click_button 'Add permission'

    expect(page).to have_css('#object-permissions-table tbody tr', text: 'sdr:new-curators Edit')
    expect(page).to have_css('#object-permissions-table tbody tr', count: 2)
    expect(page).to have_toast('Permission added')

    click_button 'Delete Read permission for sdr:curators'
    expect(page).to have_css('#object-permissions-table tbody tr', count: 1)
    expect(page).to have_toast('Permission deleted')
    click_button 'Delete Edit permission for sdr:new-curators'
    expect(page).to have_no_css('#object-permissions-table tbody tr')
    expect(page).to have_text('No permissions.')
    expect(page).to have_toast('Permission deleted')
    expect(page).to have_current_path(admin_object_permissions_path(druid))

    click_link 'Return to object'
    expect(page).to have_current_path(object_path(druid))
  end

  it 'retains a new workgroup after validation feedback so it can be corrected' do
    visit admin_object_permissions_path(druid)
    find('.ts-control input').set('sdr:new-curators')
    find('.ts-dropdown .create', text: 'sdr:new-curators').click
    find('.ts-control input').send_keys(:tab)
    click_button 'Add permission'

    expect(page).to have_text('is not included in the list')
    expect(page).to have_css('.ts-control .item', text: 'sdr:new-curators')
    choose 'Read'
    click_button 'Add permission'
    expect(page).to have_css('#object-permissions-table tbody tr', text: 'sdr:new-curators Read')
    expect(page).to have_toast('Permission added')
    expect(page).to have_no_text('is not included in the list')
    expect(page).to have_no_css(
      '#object-permission-form .is-invalid, #object-permission-form [aria-invalid="true"]', visible: :all
    )
    expect(page).to have_css('.ts-wrapper', count: 1, visible: :all)

    choose 'Edit'
    find('.ts-control').click
    find('.ts-control input').set('sdr:another-curators')
    find('.ts-dropdown .create', text: 'sdr:another-curators').click
    click_button 'Add permission'
    expect(page).to have_css('#object-permissions-table tbody tr', text: 'sdr:another-curators Edit')
    expect(page).to have_toast('Permission added')
    expect(page).to have_css('.ts-wrapper', count: 1, visible: :all)
  end

  it 'clears missing-workgroup feedback and invalid states after correction' do
    visit admin_object_permissions_path(druid)
    choose 'Read'
    click_button 'Add permission'
    expect(page).to have_text("can't be blank")
    expect(page).to have_css('#object-permission-form .is-invalid')

    find('.ts-control input').set('sdr:corrected-curators')
    find('.ts-dropdown .create', text: 'sdr:corrected-curators').click
    click_button 'Add permission'

    expect(page).to have_css('#object-permissions-table tbody tr', text: 'sdr:corrected-curators Read')
    expect(page).to have_toast('Permission added')
    expect(page).to have_no_text("can't be blank")
    expect(page).to have_no_css(
      '#object-permission-form .is-invalid, #object-permission-form [aria-invalid="true"]', visible: :all
    )
    expect(page).to have_css('.ts-wrapper', count: 1, visible: :all)
  end

  it 'clears duplicate feedback after changing the permission' do
    create(:permission, :read_restricted, workgroup: 'sdr:curators', target_druid: druid)
    visit admin_object_permissions_path(druid)
    choose 'Read'
    find('.ts-control input').set('sdr:curators')
    find('.ts-dropdown .option', text: 'sdr:curators', exact_text: true).click
    click_button 'Add permission'
    expect(page).to have_text('already has this permission')
    expect(page).to have_css('#object-permissions-table tbody tr', count: 1)

    find('h1', text: 'Manage permissions').click
    expect(page).to have_no_css('.ts-dropdown', visible: :visible)
    choose 'Edit'
    click_button 'Add permission'

    expect(page).to have_css('#object-permissions-table tbody tr', text: 'sdr:curators Read')
    expect(page).to have_css('#object-permissions-table tbody tr', text: 'sdr:curators Edit')
    expect(page).to have_toast('Permission added')
    expect(page).to have_no_text('already has this permission')
    expect(page).to have_no_css(
      '#object-permission-form .is-invalid, #object-permission-form [aria-invalid="true"]', visible: :all
    )
    expect(page).to have_css('.ts-wrapper', count: 1, visible: :all)
  end
end
