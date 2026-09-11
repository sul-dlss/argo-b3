# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin impersonate' do
  def encrypted_impersonated_workgroups
    ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash).encrypted[:impersonated_workgroups]
  end

  describe 'GET /admin/impersonate' do
    context 'when signed in as an admin user' do
      let(:admin_user) do
        create(:user, groups: [
                 AuthenticationHelpers::ADMIN_GROUP,
                 'sdr:zeta',
                 'sdr:alpha/administrator',
                 'sdr:alpha',
                 'sdr:zeta',
                 'sdr:beta'
               ])
      end

      before do
        sign_in(admin_user)
        get admin_impersonate_path
      end

      it 'allows access and renders vertically sorted workgroups without administrator suffixes' do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('sdr:alpha')
        expect(response.body).to include('sdr:beta')
        expect(response.body).to include('sdr:zeta')
        expect(response.body).not_to include('sdr:alpha/administrator')

        alpha_position = response.body.index('sdr:alpha')
        beta_position = response.body.index('sdr:beta')
        zeta_position = response.body.index('sdr:zeta')

        expect(alpha_position).to be < beta_position
        expect(beta_position).to be < zeta_position
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
      create(:user,
             groups: [AuthenticationHelpers::ADMIN_GROUP, 'sdr:group-a', 'sdr:group-b', 'sdr:group-c/administrator'])
    end

    before do
      sign_in(admin_user)
    end

    it 'stores selected allowed workgroups in encrypted cookies' do
      patch admin_impersonate_path, params: {
        impersonation: {
          workgroups: ['sdr:group-b', 'sdr:group-a']
        }
      }

      expect(response).to redirect_to(admin_impersonate_path)
      expect(encrypted_impersonated_workgroups).to eq(['sdr:group-a', 'sdr:group-b'])
    end

    it 'filters out workgroups not available to the admin' do
      patch admin_impersonate_path, params: {
        impersonation: {
          workgroups: ['sdr:group-a', 'sdr:not-allowed', 'sdr:group-d']
        }
      }

      expect(encrypted_impersonated_workgroups).to eq(['sdr:group-a'])
    end

    it 'clears cookie when no workgroups are selected' do
      patch admin_impersonate_path, params: {
        impersonation: {
          workgroups: ['sdr:group-a']
        }
      }

      expect(encrypted_impersonated_workgroups).to eq(['sdr:group-a'])

      patch admin_impersonate_path, params: { impersonation: { workgroups: [] } }

      get admin_impersonate_path

      expect(encrypted_impersonated_workgroups).to be_nil
    end

    context 'when signed in as a non-admin user' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'is unauthorized' do
        patch admin_impersonate_path, params: { impersonation: { workgroups: ['sdr:group-a'] } }

        expect(response).to be_unauthorized
      end
    end
  end

  describe 'DELETE /admin/impersonate' do
    let(:admin_user) { create(:user, :admin) }

    before do
      sign_in(admin_user)
      patch admin_impersonate_path, params: { impersonation: { workgroups: ['sdr:group-a'] } }
    end

    it 'deletes the impersonation cookie' do
      delete admin_stop_impersonate_path

      expect(response).to redirect_to(admin_impersonate_path)

      get admin_impersonate_path

      expect(encrypted_impersonated_workgroups).to be_nil
    end
  end

  describe 'GET /admin/impersonate while impersonating as non-admin' do
    let(:admin_user) { create(:user, :admin, groups: [AuthenticationHelpers::ADMIN_GROUP, 'sdr:group-a']) }
    let(:user) { create(:user, groups: ['sdr:user-group']) }

    before do
      sign_in(admin_user)
      patch admin_impersonate_path, params: { impersonation: { workgroups: ['sdr:group-a'] } }
      sign_in(user)
    end

    it 'allows access' do
      get admin_impersonate_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'DELETE /admin/impersonate while impersonating as non-admin' do
    let(:admin_user) { create(:user, :admin, groups: [AuthenticationHelpers::ADMIN_GROUP, 'sdr:group-a']) }
    let(:user) { create(:user, groups: ['sdr:user-group']) }

    before do
      sign_in(admin_user)
      patch admin_impersonate_path, params: { impersonation: { workgroups: ['sdr:group-a'] } }
      sign_in(user)
    end

    it 'allows clearing impersonation' do
      delete admin_stop_impersonate_path

      expect(response).to redirect_to(admin_impersonate_path)

      get admin_impersonate_path

      expect(encrypted_impersonated_workgroups).to be_nil
    end
  end
end
