# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show dashboard', :rack_test do
  context 'when signed in as a regular user' do
    before { sign_in(create(:user)) }

    it 'displays the button lists and tables, but not the admin button list' do
      visit root_path

      expect(page).to have_css('h1', text: 'Argo dashboard')

      expect(page).to have_css('h2', text: 'Register & deposit single object')
      expect(page).to have_button('Item')
      expect(page).to have_css('a.disabled', text: 'Item')

      expect(page).to have_css('h2', text: 'Register or deposit multiple items')
      expect(page).to have_button('Register multiple items')

      expect(page).to have_no_css('h2', text: 'Admin')
      expect(page).to have_no_button('Manage permissions')
      expect(page).to have_no_button('Impersonate')

      expect(page).to have_css('table caption', text: 'Recent objects')
      expect(page).to have_css('table[aria-label="Pinned searches"]')
      expect(page).to have_css('table[aria-label="Pinned items"]')
    end
  end

  context 'when signed in as a user with edit permission' do
    let(:workgroup) { 'sdr:test-workgroup' }

    before do
      create(:permission, :edit, workgroup:)
      sign_in(create(:user, groups: [workgroup]))
    end

    it 'enables the Item button' do
      visit root_path

      expect(page).to have_link('Item', href: new_item_path)
      expect(page).to have_no_css('a.disabled', text: 'Item')
    end
  end

  context 'when signed in as an admin user' do
    before { sign_in(create(:user, :admin)) }

    it 'displays the admin button list' do
      visit root_path

      expect(page).to have_css('h2', text: 'Admin')
      expect(page).to have_button('Manage permissions')
      expect(page).to have_button('Impersonate')
    end
  end
end
