# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Search and report permissions', :solr do
  let(:user) { create(:user, :reader) }
  let(:restricted_apo_druid) { 'druid:bc123df4567' }
  let!(:visible_document) { create(:solr_item, title: 'Visible item', projects: ['Visible project']) }
  let!(:hidden_document) do
    create(:solr_item, title: 'Hidden item', apo_druid: restricted_apo_druid, projects: ['Hidden project'])
  end

  before do
    create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: restricted_apo_druid)
    sign_in(user)
  end

  it 'only renders readable items through the search endpoint' do
    get search_items_path, params: { query: 'item' }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Visible item')
    expect(response.body).not_to include('Hidden item')
  end

  it 'only suggests projects found on readable items' do
    get search_projects_path, params: { query: 'project' }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Visible project')
    expect(response.body).not_to include('Hidden project')
  end

  %w[druids results].each do |source|
    it "filters both preview and download reports from #{source}" do
      get search_items_path, params: { query: 'item' }
      report = { source:, fields: [Search::Fields::TITLE],
                 druid_list: [visible_document, hidden_document].pluck(Search::Fields::ID).join("\n") }

      post preview_report_path, params: { report:, commit: 'Preview' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Visible item')
      expect(response.body).not_to include('Hidden item')

      post download_report_path, params: { report:, commit: 'Download' }

      expect(response).to have_http_status(:ok)
      expect(CSV.parse(response.body, headers: true).map(&:fields)).to eq([['Visible item']])
    end
  end

  context 'without read permissions' do
    let(:user) { create(:user) }

    it 'returns no items even when explicitly searching for a hidden druid' do
      get search_items_path, params: { query: hidden_document.fetch(Search::Fields::ID) }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Visible item', 'Hidden item')
    end
  end
end
