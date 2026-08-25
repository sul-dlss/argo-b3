# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PinnedSearches' do
  let(:user) { create(:user) }
  let(:search_form) { SearchForm.new(query: 'test') }

  before do
    sign_in(user)
  end

  describe 'POST /pinned_searches' do
    it 'creates a pinned search for the current user and shows a toast' do
      expect do
        post pinned_searches_path, params: search_form.attributes
      end.to change(PinnedSearch, :count).by(1)

      expect(response).to redirect_to(root_path)
      expect(response).to have_http_status(:see_other)
      expect(flash[:toast]).to eq('Pin added')
      expect(PinnedSearch.last.user).to eq(user)
      expect(PinnedSearch.last.search_form_attributes).to eq(search_form.attributes)
    end

    it 'is idempotent when the search is already pinned' do
      PinnedSearch.create_from_search_form(search_form:, user:)

      expect do
        post pinned_searches_path, params: search_form.attributes
      end.not_to change(PinnedSearch, :count)
      expect(response).to have_http_status(:see_other)
    end
  end

  describe 'DELETE /pinned_searches/:id' do
    let!(:pinned_search) { PinnedSearch.create_from_search_form(search_form:, user:) }

    it 'destroys the pinned search and shows a toast' do
      expect do
        delete pinned_search_path(pinned_search.search_form_md5)
      end.to change(PinnedSearch, :count).by(-1)

      expect(response).to redirect_to(root_path)
      expect(response).to have_http_status(:see_other)
      expect(flash[:toast]).to eq('Pin removed')
    end

    it 'does not destroy a pinned search belonging to another user' do
      sign_in(create(:user))

      expect do
        delete pinned_search_path(pinned_search.search_form_md5)
      end.not_to change(PinnedSearch, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
