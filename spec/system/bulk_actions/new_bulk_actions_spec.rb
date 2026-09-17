# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'New bulk actions', :rack_test do
  before do
    sign_in(create(:user))
  end

  it 'lists the available bulk actions' do
    visit new_bulk_action_path

    expect(page).to have_css('h1', text: 'New bulk actions')

    within('section#perform-actions-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Perform actions')
      expect(page).to have_link('Manage release')
      expect(page).to have_link('Republish')
      expect(page).to have_link('Reindex')
      expect(page).to have_css('p', text: 'Reindex objects in Solr.')
      expect(page).to have_css('li', count: 3)
    end

    within('section#modify-objects-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Modify objects')
      expect(page).to have_link('Redeposit')
      expect(page).to have_css('li', count: 5)
    end

    within('section#manage-descriptive-metadata-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Manage descriptive metadata')
      expect(page).to have_link('Refresh metadata from FOLIO')
      expect(page).to have_css('li', count: 7)
    end

    within('section#manage-rights-and-administrative-metadata-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Manage rights and administrative metadata')
      expect(page).to have_link('Update rights')
      expect(page).to have_link('Update source ID')
      expect(page).to have_css('li', count: 6)
    end

    within('section#manage-structural-metadata-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Manage structural metadata')
      expect(page).to have_link('Update content type')
      expect(page).to have_css('li', count: 5)
    end

    within('section#tags-and-reporting-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Tags and reporting')
      expect(page).to have_link('Export tags')
      expect(page).to have_css('li', count: 5)
    end
  end
end
