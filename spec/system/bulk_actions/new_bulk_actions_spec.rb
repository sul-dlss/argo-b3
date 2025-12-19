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
      expect(page).to have_link('Reindex')
      expect(page).to have_css('p', text: 'Reindexes the DOR object in Solr.')
      expect(page).to have_css('li', count: 4)
    end

    within('section#modify-objects-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Modify objects')
      expect(page).to have_css('span', text: 'Open new version')
    end

    within('section#manage-descriptive-metadata-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Manage descriptive metadata')
      expect(page).to have_css('span', text: 'Refresh metadata from FOLIO record')
    end

    within('section#manage-rights-and-administrative-metadata-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Manage rights and administrative metadata')
      expect(page).to have_css('span', text: 'Update rights')
    end

    within('section#manage-structural-metadata-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Manage structural metadata')
      expect(page).to have_css('span', text: 'Update content type')
    end

    within('section#tags-and-reporting-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Tags and reporting')
      expect(page).to have_link('Export tags')
    end
  end
end
