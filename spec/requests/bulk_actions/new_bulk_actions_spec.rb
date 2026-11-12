# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk actions menu' do
  let(:rendered_page) { Capybara.string(response.body) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  it 'lists the available bulk actions' do
    get new_bulk_action_path

    expect(response).to have_http_status(:ok)
    expect(rendered_page).to have_css('h1', text: 'Bulk actions menu')
    expect(rendered_page).to have_title('Bulk actions menu | Argo B3', exact: true)

    expect(rendered_page.all('section h2').map(&:text)).to eq(
      ['Perform actions', 'Register and deposit', 'Tags and reporting',
       'Modify objects', 'Manage structural metadata', 'Manage rights and administrative metadata',
       'Manage descriptive metadata']
    )

    rendered_page.find('section#perform-actions-bulk-actions-section') do |section|
      expect(section).to have_css('h2', text: 'Perform actions')
      expect(section).to have_link('Manage release')
      expect(section).to have_link('Republish')
      expect(section).to have_link('Reindex')
      expect(section).to have_css('p', text: 'Reindex objects in Solr.')
      expect(section).to have_css('li', count: 3)
    end

    rendered_page.find('section#register-and-deposit-bulk-actions-section') do |section|
      expect(section).to have_css('h2', text: 'Register and deposit')
      expect(section).to have_link('Register items')
      expect(section).to have_link('Redeposit')
      expect(section).to have_css('li', count: 2)
    end

    rendered_page.find('section#modify-objects-bulk-actions-section') do |section|
      expect(section).to have_css('h2', text: 'Modify objects')
      expect(section).to have_link('Add workflow')
      expect(section).to have_no_link('Redeposit')
      expect(section).to have_css('li', count: 3)
    end

    rendered_page.find('section#manage-descriptive-metadata-bulk-actions-section') do |section|
      expect(section).to have_css('h2', text: 'Manage descriptive metadata')
      expect(section).to have_link('Refresh metadata from FOLIO')
      expect(section).to have_css('li', count: 7)
    end

    rendered_page.find('section#manage-rights-and-administrative-metadata-bulk-actions-section') do |section|
      expect(section).to have_css('h2', text: 'Manage rights and administrative metadata')
      expect(section).to have_link('Update rights')
      expect(section).to have_link('Update source ID')
      expect(section).to have_css('li', count: 6)
    end

    rendered_page.find('section#manage-structural-metadata-bulk-actions-section') do |section|
      expect(section).to have_css('h2', text: 'Manage structural metadata')
      expect(section).to have_link('Update content type')
      expect(section).to have_css('li', count: 5)
    end

    rendered_page.find('section#tags-and-reporting-bulk-actions-section') do |section|
      expect(section).to have_css('h2', text: 'Tags and reporting')
      expect(section).to have_link('Export tags')
      expect(section).to have_css('li', count: 5)
    end
  end

  context 'when the user is an admin' do
    let(:user) { create(:user, :admin) }

    it 'lists the manage permissions section last' do
      get new_bulk_action_path

      expect(rendered_page.all('section h2').last.text).to eq('Manage permissions')
    end
  end
end
