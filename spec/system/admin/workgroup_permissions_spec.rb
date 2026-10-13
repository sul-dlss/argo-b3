# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin workgroup permissions' do
  let(:admin_user) { create(:user, groups: [AuthenticationHelpers::ADMIN_GROUP]) }

  before do
    create(:permission, :read_unrestricted, workgroup: 'sdr:alpha')
    create(:permission, :read_restricted, workgroup: 'sdr:alpha', target_druid: 'druid:bc123df4567')
    allow(Searchers::ItemByDruid).to receive(:call).and_return([])
    sign_in(admin_user)
  end

  it 'refreshes the table and shows the empty message and toast after deleting the last additional permission' do
    visit edit_admin_workgroup_permission_path('sdr:alpha')
    expect(page).to have_css('#additional-permissions-table tbody tr', count: 1)

    click_button 'Delete permission for druid:bc123df4567'

    expect(page).to have_text('No additional permissions.')
    expect(page).to have_no_css('#additional-permissions-table tbody tr')
    expect(page).to have_toast('Permission deleted')
    expect(page).to have_current_path(edit_admin_workgroup_permission_path('sdr:alpha'))
    expect(page).to have_checked_field('Yes')
  end
end
