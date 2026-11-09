# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin impersonate' do
  def encrypted_impersonated_workgroups
    ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash).encrypted[:impersonated_workgroups]
  end

  describe 'GET /admin/impersonate' do
    context 'when signed in as an admin user' do
      let(:admin_user) do
        create(:user, groups: [AuthenticationHelpers::ADMIN_GROUP, 'sdr:not-listed'])
      end

      before do
        sign_in(admin_user)
        get admin_impersonate_path
      end

      it 'allows access and renders the listed workgroups in order, not the admin’s own groups' do
        expect(response).to have_http_status(:ok)
        expect(Capybara.string(response.body)).to have_title('Impersonate | Argo B3', exact: true)
        expect(response.body).not_to include('sdr:not-listed')

        first_position = response.body.index('sdr:3d-staff')
        middle_position = response.body.index('sdr:map-staff')
        last_position = response.body.index('sdr:was-staff')

        expect(first_position).to be < middle_position
        expect(middle_position).to be < last_position
      end
    end

    context 'when signed in as a non-admin user' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'redirects to root' do
        get admin_impersonate_path

        expect(response).to be_unauthorized
      end
    end
  end

  describe 'PATCH /admin/impersonate' do
    let(:admin_user) do
      create(:user, groups: [AuthenticationHelpers::ADMIN_GROUP, 'sdr:not-listed'])
    end

    before do
      sign_in(admin_user)
    end

    it 'stores selected allowed workgroups in encrypted cookies' do
      patch admin_impersonate_path, params: {
        impersonation: {
          workgroups: ['sdr:map-staff', 'sdr:hoover-staff']
        }
      }

      expect(response).to redirect_to(root_path)
      expect(flash[:success]).to eq('You are now impersonating the selected workgroups.')
      expect(encrypted_impersonated_workgroups).to eq(['sdr:hoover-staff', 'sdr:map-staff'])
    end

    it 'filters out workgroups that are not listed, including the admin’s own' do
      patch admin_impersonate_path, params: {
        impersonation: {
          workgroups: ['sdr:map-staff', 'sdr:not-listed', 'sdr:not-allowed']
        }
      }

      expect(encrypted_impersonated_workgroups).to eq(['sdr:map-staff'])
    end

    it 'does not enable impersonation when no workgroups are selected' do
      patch admin_impersonate_path, params: { impersonation: { workgroups: [] } }

      expect(response).to redirect_to(admin_impersonate_path)
      expect(flash[:danger]).to eq('You must select workgroups to enable impersonation.')
      expect(encrypted_impersonated_workgroups).to be_nil
    end

    context 'when signed in as a non-admin user' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'is unauthorized' do
        patch admin_impersonate_path, params: { impersonation: { workgroups: ['sdr:map-staff'] } }

        expect(response).to be_unauthorized
      end
    end
  end

  describe 'DELETE /admin/impersonate' do
    let(:admin_user) { create(:user, :admin, groups: [AuthenticationHelpers::ADMIN_GROUP, 'sdr:map-staff']) }

    before do
      sign_in(admin_user)
      patch admin_impersonate_path, params: { impersonation: { workgroups: ['sdr:map-staff'] } }
    end

    it 'deletes the impersonation cookie' do
      delete admin_stop_impersonate_path

      expect(response).to redirect_to(root_path)
      expect(flash[:success]).to eq('You have stopped impersonating.')

      get admin_impersonate_path

      expect(encrypted_impersonated_workgroups).to be_nil
    end
  end

  describe 'DELETE /admin/impersonate when not impersonating' do
    let(:admin_user) { create(:user, :admin) }

    before do
      sign_in(admin_user)
    end

    it 'is unauthorized' do
      delete admin_stop_impersonate_path

      expect(response).to be_unauthorized
    end
  end

  describe 'GET /admin/impersonate while an admin is impersonating an admin group' do
    let(:admin_user) { create(:user, :admin) }

    before do
      sign_in(admin_user)
      patch admin_impersonate_path, params: { impersonation: { workgroups: [AuthenticationHelpers::ADMIN_GROUP] } }
    end

    it 'is unauthorized' do
      get admin_impersonate_path

      expect(response).to be_unauthorized
    end
  end

  describe 'GET /admin/impersonate while impersonating as non-admin' do
    let(:admin_user) { create(:user, :admin, groups: [AuthenticationHelpers::ADMIN_GROUP, 'sdr:map-staff']) }
    let(:user) { create(:user, groups: ['sdr:user-group']) }

    before do
      sign_in(admin_user)
      patch admin_impersonate_path, params: { impersonation: { workgroups: ['sdr:map-staff'] } }
      sign_in(user)
    end

    it 'denies access' do
      get admin_impersonate_path

      expect(response).to be_unauthorized
    end
  end

  describe 'DELETE /admin/impersonate while impersonating as non-admin' do
    let(:admin_user) { create(:user, :admin, groups: [AuthenticationHelpers::ADMIN_GROUP, 'sdr:map-staff']) }
    let(:user) { create(:user, groups: ['sdr:user-group']) }

    before do
      sign_in(admin_user)
      patch admin_impersonate_path, params: { impersonation: { workgroups: ['sdr:map-staff'] } }
      sign_in(user)
    end

    it 'allows clearing impersonation' do
      delete admin_stop_impersonate_path

      expect(response).to redirect_to(root_path)
      expect(flash[:success]).to eq('You have stopped impersonating.')

      get admin_impersonate_path

      expect(encrypted_impersonated_workgroups).to be_nil
    end
  end
end
