# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tag suggestions' do
  let(:user) { create(:user, :reader) }

  before do
    allow(Searchers::TagSuggestions).to receive(:call).and_return(['Argo Project : Phase 1'])
    sign_in(user)
  end

  it 'returns the matching tags as JSON options' do
    get '/tag_suggestions', params: { q: 'argo', type: 'project' }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq([{ 'value' => 'Argo Project : Phase 1', 'text' => 'Argo Project : Phase 1' }])
    expect(Searchers::TagSuggestions).to have_received(:call)
      .with(query: 'argo', tag_type: 'project', user_scope: an_instance_of(Permissions::UserScope))
  end

  context 'when the query is missing' do
    it 'returns a bad request' do
      get '/tag_suggestions', params: { type: 'project' }

      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'when the type is missing' do
    it 'returns a bad request' do
      get '/tag_suggestions', params: { q: 'argo' }

      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'when the type is unknown' do
    it 'returns a bad request' do
      get '/tag_suggestions', params: { q: 'argo', type: 'registered_by' }

      expect(response).to have_http_status(:bad_request)
      expect(Searchers::TagSuggestions).not_to have_received(:call)
    end
  end
end
