# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Catalog titles' do
  let(:user) { create(:user, :reader) }

  before do
    sign_in(user)
  end

  context 'when the catalog record has a title' do
    before do
      allow(CatalogRepository).to receive(:title).and_return('The Title')
    end

    it 'returns the title as JSON' do
      get '/catalog_titles', params: { catalog_record_id: ' in11403803 ' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({ 'title' => 'The Title' })
      expect(CatalogRepository).to have_received(:title).with(catalog_record_id: 'in11403803')
    end
  end

  context 'when the catalog record is not found' do
    before do
      allow(CatalogRepository).to receive(:title).and_return(nil)
    end

    it 'returns a not found error' do
      get '/catalog_titles', params: { catalog_record_id: 'in11403803' }

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq({ 'error' => 'FOLIO record not found' })
    end
  end

  context 'when the catalog request fails' do
    before do
      allow(CatalogRepository).to receive(:title).and_raise(CatalogRepository::Error, 'Folio is down')
    end

    it 'returns a bad gateway error' do
      get '/catalog_titles', params: { catalog_record_id: 'in11403803' }

      expect(response).to have_http_status(:bad_gateway)
      expect(response.parsed_body)
        .to eq({ 'error' => "Connection with FOLIO couldn't be established" })
    end
  end

  context 'when the catalog record id is missing' do
    before do
      allow(CatalogRepository).to receive(:title)
    end

    it 'returns an error without querying the catalog' do
      get '/catalog_titles', params: { catalog_record_id: '  ' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq({ 'error' => 'Enter a FOLIO Instance HRID.' })
      expect(CatalogRepository).not_to have_received(:title)
    end
  end

  context 'when unauthenticated' do
    before do
      allow(CatalogRepository).to receive(:title)
      reset!
    end

    it 'redirects to login without querying the catalog' do
      get '/catalog_titles', params: { catalog_record_id: 'in11403803' }

      expect(response).to redirect_to(login_path)
      expect(CatalogRepository).not_to have_received(:title)
    end
  end
end
