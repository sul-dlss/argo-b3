# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection options' do
  let(:user) { create(:user, :reader) }

  before do
    allow(Searchers::CollectionList).to receive(:call).and_return([['Art History Slides', 'druid:bc123df4567']])
    allow(Searchers::CollectionListByDruid).to receive(:call)
      .and_return([['Maps of Palo Alto', 'druid:xz987wv6543']])
    sign_in(user)
  end

  context 'with a title query' do
    it 'returns the collections matching the title as JSON options' do
      get '/collection_options', params: { q: ' art hist ' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([{ 'value' => 'druid:bc123df4567', 'text' => 'Art History Slides' }])
      expect(Searchers::CollectionList).to have_received(:call)
        .with(query: 'art hist', user_scope: an_instance_of(Permissions::UserScope), apo_druid: nil)
      expect(Searchers::CollectionListByDruid).not_to have_received(:call)
    end
  end

  context 'with a bare druid query' do
    it 'returns the collection with the druid as a JSON option' do
      get '/collection_options', params: { q: 'xz987wv6543' }

      expect(response.parsed_body).to eq([{ 'value' => 'druid:xz987wv6543', 'text' => 'Maps of Palo Alto' }])
      expect(Searchers::CollectionListByDruid).to have_received(:call)
        .with(druids: ['druid:xz987wv6543'], user_scope: an_instance_of(Permissions::UserScope), apo_druid: nil)
      expect(Searchers::CollectionList).not_to have_received(:call)
    end
  end

  context 'with a prefixed druid query' do
    it 'returns the collection with the druid as a JSON option' do
      get '/collection_options', params: { q: 'druid:xz987wv6543' }

      expect(Searchers::CollectionListByDruid).to have_received(:call)
        .with(druids: ['druid:xz987wv6543'], user_scope: an_instance_of(Permissions::UserScope), apo_druid: nil)
    end
  end

  context 'when limiting by APO' do
    it 'limits title queries to the collections governed by the APO' do
      get '/collection_options', params: { q: 'art', limit_by_apo: '1', apo_druid: 'druid:hv992ry2431' }

      expect(Searchers::CollectionList).to have_received(:call)
        .with(query: 'art', user_scope: an_instance_of(Permissions::UserScope), apo_druid: 'druid:hv992ry2431')
    end

    it 'limits druid queries to the collections governed by the APO' do
      get '/collection_options', params: { q: 'xz987wv6543', limit_by_apo: '1', apo_druid: 'druid:hv992ry2431' }

      expect(Searchers::CollectionListByDruid).to have_received(:call)
        .with(druids: ['druid:xz987wv6543'], user_scope: an_instance_of(Permissions::UserScope),
              apo_druid: 'druid:hv992ry2431')
    end

    context 'when no APO is selected' do
      it 'does not limit by APO' do
        get '/collection_options', params: { q: 'art', limit_by_apo: '1' }

        expect(Searchers::CollectionList).to have_received(:call)
          .with(query: 'art', user_scope: an_instance_of(Permissions::UserScope), apo_druid: nil)
      end
    end
  end

  context 'when not limiting by APO' do
    it 'does not limit by the selected APO' do
      get '/collection_options', params: { q: 'art', apo_druid: 'druid:hv992ry2431' }

      expect(Searchers::CollectionList).to have_received(:call)
        .with(query: 'art', user_scope: an_instance_of(Permissions::UserScope), apo_druid: nil)
    end
  end

  context 'when the query is missing' do
    it 'returns a bad request' do
      get '/collection_options'

      expect(response).to have_http_status(:bad_request)
    end
  end
end
