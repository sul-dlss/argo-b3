# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Workflow grid', :solr do
  before do
    create(:solr_item, :with_workflows, title: 'Mark Twain : portrait for orchestra')
    create_list(:solr_item, 2, :with_workflows)
    sign_in(create(:user, :reader))

    allow(Dor::Services::Client.workflows).to receive(:templates).and_return(['accessionWF'])
    allow(Dor::Services::Client.workflows).to receive(:template).with('accessionWF').and_return(ACCESSIONWF_TEMPLATE)
  end

  describe 'the placeholder frame' do
    # The search is serialized into a URL twice: once for the page and again for the frame that
    # loads the real data. If the frame src dropped an attribute, the grid would count a different
    # set of objects than the current filters above it claim.
    it 'carries the search through to the frame that loads the real data' do
      get workflow_grid_path, params: { query: 'twain', object_types: ['item'], tags: ['Tag 1'] }

      expect(response).to have_http_status(:ok)
      frame = response.body[/<turbo-frame[^>]*id="workflow-grid"[^>]*>/]
      frame_src = CGI.unescapeHTML(frame.to_s[/src="([^"]*)"/, 1].to_s)
      expect(frame_src).to eq(
        '/workflow_grid?object_types%5B%5D=item&placeholder=false&query=twain&tags%5B%5D=Tag+1'
      )
    end

    it 'returns the process counts for the objects matching the search' do
      get workflow_grid_path, params: { query: 'twain', placeholder: 'false' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('workflow-table-accessionWF')
    end
  end

  describe 'the facet sidebar' do
    it 'points the facet endpoints at the workflow grid so refining stays on the grid' do
      get workflow_grid_path, params: { query: 'twain' }

      expect(response.body).to include('/workflow_grid/tag_facets')
      expect(response.body).not_to include('/search/tag_facets')
    end
  end

  describe 'the view toggle' do
    it 'links to the search results view with the same search' do
      get workflow_grid_path, params: { query: 'twain' }

      expect(response.body).to include('href="/search?query=twain"')
    end
  end
end
