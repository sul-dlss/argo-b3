# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'New bulk actions', :rack_test do
  it 'lists the available bulk actions' do
    visit new_bulk_action_path

    expect(page).to have_css('h1', text: 'New bulk actions')

    within('section#perform-actions-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Perform actions')
      expect(page).to have_link('Manage release')
      expect(page).to have_css('p', text: 'Adds release tags to individual objects.')
      expect(page).to have_css('a[href]', count: 3)
    end

    within('section#modify-objects-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Modify objects')
      expect(page).to have_link('Open new version')
    end

    within('section#manage-descriptive-metadata-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Manage descriptive metadata')
      expect(page).to have_link('Refresh metadata from FOLIO record')
    end

    within('section#manage-rights-and-administrative-metadata-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Manage rights and administrative metadata')
      expect(page).to have_link('Update rights')
    end

    within('section#manage-structural-metadata-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Manage structural metadata')
      expect(page).to have_link('Update content type')
    end

    within('section#tags-and-reporting-bulk-actions-section') do
      expect(page).to have_css('h2', text: 'Tags and reporting')
      expect(page).to have_link('Export tags')
    end
  end
end
