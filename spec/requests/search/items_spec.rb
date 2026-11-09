# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item search', :solr do
  before do
    create(:solr_item, title: 'Test map of the coast')
    sign_in(create(:user, :reader))
  end

  context 'when requested from a turbo-frame' do
    it 'renders the items frame' do
      get search_items_path, params: { query: 'test' }, headers: { 'Turbo-Frame' => 'items-search' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('turbo-frame id="items-search"')
      expect(heading_outline(response.body).drop_while { |level, _| level != 2 }.first(2))
        .to match [[2, 'Item, collection, and APO results (1 found)'],
                   [3, a_string_starting_with('1. Test map of the coast')]]
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
