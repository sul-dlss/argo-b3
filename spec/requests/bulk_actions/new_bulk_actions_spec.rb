# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'New bulk actions' do
  let(:rendered_page) { Capybara.string(response.body) }

  before do
    sign_in(create(:user))
  end

  it 'lists the available bulk actions' do
    get new_bulk_action_path

    expect(response).to have_http_status(:ok)
    expect(rendered_page).to have_css('h1', text: 'New bulk actions')

    rendered_page.find('section#perform-actions-bulk-actions-section') do |section|
      expect(section).to have_css('h2', text: 'Perform actions')
      expect(section).to have_link('Manage release')
      expect(section).to have_link('Republish')
      expect(section).to have_link('Reindex')
      expect(section).to have_css('p', text: 'Reindex objects in Solr.')
      expect(section).to have_css('li', count: 3)
    end

    rendered_page.find('section#modify-objects-bulk-actions-section') do |section|
      expect(section).to have_css('h2', text: 'Modify objects')
      expect(section).to have_link('Redeposit')
      expect(section).to have_css('li', count: 5)
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
end
