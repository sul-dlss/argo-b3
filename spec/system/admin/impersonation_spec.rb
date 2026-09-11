# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin impersonation', :rack_test do
  let(:admin_user) do
    create(:user, groups: [AuthenticationHelpers::ADMIN_GROUP, 'sdr:workgroup-a', 'sdr:workgroup-b',
                           'sdr:workgroup-c/administrator'])
  end

  before do
    sign_in(admin_user)
  end

  it 'lets admin choose workgroups to impersonate and stop impersonating from header nav' do
    visit root_path

    expect(page).to have_link('Impersonate', href: admin_impersonate_path)
    expect(page).to have_no_link('Stop impersonating')

    visit admin_impersonate_path

    expect(page).to have_text('Select one or more workgroups to impersonate')
    expect(page).to have_no_field('sdr:workgroup-c/administrator')

    check 'sdr:workgroup-a'
    click_button 'Impersonate'

    expect(page).to have_link('Stop impersonating', href: admin_stop_impersonate_path)

    visit root_path
    expect(page).to have_link('Impersonate', href: admin_impersonate_path)

    click_link 'Stop impersonating'

    expect(page).to have_current_path(admin_impersonate_path)
    expect(page).to have_no_link('Stop impersonating')
  end

  it 'removes impersonation when no groups are selected' do
    visit admin_impersonate_path

    check 'sdr:workgroup-a'
    click_button 'Impersonate'
    expect(page).to have_link('Stop impersonating', href: admin_stop_impersonate_path)

    uncheck 'sdr:workgroup-a'
    click_button 'Impersonate'

    expect(page).to have_no_link('Stop impersonating')
  end
end
