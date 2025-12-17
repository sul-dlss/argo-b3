# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin groups' do
  context 'when signed in as an admin user' do
    let(:admin_user) { create(:user, :admin) }

    before do
      sign_in(admin_user)
    end

    it 'allows access to the groups page' do
      get admin_groups_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(AdminPolicy::ADMIN_GROUP)
    end
  end

  context 'when signed in as a non-admin user' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    it 'redirects to root' do
      get admin_groups_path

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('You are not authorized to perform the requested action.')
    end
  end
end
