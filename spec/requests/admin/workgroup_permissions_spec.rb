# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin workgroup permissions' do
  describe 'GET /admin/workgroup_permissions' do
    context 'when signed in as an admin user' do
      let(:admin_user) { create(:user, groups: [AuthenticationHelpers::ADMIN_GROUP]) }
      let(:rendered_page) { Capybara.string(response.body) }

      before do
        create(:permission, :read_unrestricted, workgroup: 'sdr:gamma')
        create(:permission, :read_unrestricted, workgroup: 'sdr:alpha')
        create_list(:permission, 2, :edit, workgroup: 'sdr:alpha')
        create(:permission, :read_restricted, workgroup: 'sdr:beta')

        sign_in(admin_user)
        get admin_workgroup_permissions_path
      end

      it 'renders workgroups sorted with their permission counts and read unrestricted status' do
        expect(response).to have_http_status(:ok)

        rows = rendered_page.all('#workgroup-permissions-table tbody tr')
        expect(rows.map { |row| row.all('td').map(&:text) }).to eq(
          [
            %w[sdr:alpha 2 Yes],
            %w[sdr:beta 1 No],
            %w[sdr:gamma 0 Yes]
          ]
        )
      end
    end

    context 'when signed in as a non-admin user' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'returns unauthorized' do
        get admin_workgroup_permissions_path

        expect(response).to be_unauthorized
      end
    end
  end
end
