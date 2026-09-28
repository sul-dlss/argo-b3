# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item search', :solr do
  before do
    create(:solr_item)
    sign_in(create(:user, :reader))
  end

  context 'when requested from a turbo-frame' do
    it 'renders the items frame' do
      get search_items_path, params: { query: 'test' }, headers: { 'Turbo-Frame' => 'items-search' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-frame id="items-search"')
    end
  end

  context 'when not requested from a turbo-frame' do
    it 'redirects to the search page' do
      get search_items_path, params: { query: 'test', page: 2 }

      expect(response).to redirect_to(search_path(query: 'test', page: 2))
    end
  end

  context 'when not requested from a turbo-frame for the workflow grid' do
    it 'redirects to the workflow grid page' do
      get workflow_grid_items_path, params: { query: 'test' }

      expect(response).to redirect_to(workflow_grid_path(query: 'test'))
    end
  end
end
