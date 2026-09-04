# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Impersonation permissions' do
  describe 'GET /dashboard' do
    let(:user) { create(:user, groups: ['sdr:actual-group']) }

    before do
      sign_in(user)
    end

    context 'when effective groups from impersonation have edit permission' do
      let(:admin_user) { create(:user, :admin, groups: [AuthenticationHelpers::ADMIN_GROUP, 'sdr:impersonated-group']) }

      before do
        create(:permission, :edit, workgroup: 'sdr:impersonated-group')
        sign_in(admin_user)
        patch admin_impersonate_path, params: { impersonation: { workgroups: ['sdr:impersonated-group'] } }
        sign_in(user)
      end

      it 'enables the Item link when effective groups are impersonated groups' do
        get root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('href="/items/new"')
      end
    end

    context 'when actual groups have edit permission but impersonated groups do not' do
      let(:admin_user) { create(:user, :admin, groups: [AuthenticationHelpers::ADMIN_GROUP, 'sdr:no-permission-group']) }

      before do
        create(:permission, :edit, workgroup: 'sdr:actual-group')
        sign_in(admin_user)
        patch admin_impersonate_path, params: { impersonation: { workgroups: ['sdr:no-permission-group'] } }
        sign_in(user)
      end

      it 'disables the Item link because effective groups are impersonated groups' do
        get root_path

        expect(response).to have_http_status(:ok)

        rendered_page = Capybara.string(response.body)
        expect(rendered_page).to have_button('Item', class: 'btn btn-outline-primary disabled')
      end
    end
  end
end
