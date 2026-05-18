# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Register bulk action' do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET new' do
    context 'when a last search cookie is present' do
      before do
        cookies[:last_search] = signed_last_search_cookie
      end

      it 'renders successfully without error' do
        get new_bulk_actions_register_path

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
