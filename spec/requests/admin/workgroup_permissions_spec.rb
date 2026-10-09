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

  describe 'GET /admin/workgroup_permissions/:workgroup/edit' do
    context 'when signed in as an admin user' do
      let(:admin_user) { create(:user, groups: [AuthenticationHelpers::ADMIN_GROUP]) }
      let(:rendered_page) { Capybara.string(response.body) }

      before do
        create(:permission, :read_unrestricted, workgroup: 'sdr:alpha')
        create(:permission, :read_restricted, workgroup: 'sdr:alpha', target_druid: 'druid:bc123df4567')

        allow(Searchers::ItemByDruid).to receive(:call).and_return(
          [
            SearchResults::Item.new(solr_doc: {
                                      Search::Fields::ID => 'druid:bc123df4567',
                                      Search::Fields::TITLE => 'Restricted collection',
                                      Search::Fields::OBJECT_TYPES => ['collection']
                                    })
          ]
        )

        sign_in(admin_user)
        get edit_admin_workgroup_permission_path('sdr:alpha')
      end

      it 'renders the workgroup, the read unrestricted toggle, and the other permissions table' do
        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_css('h1', text: 'sdr:alpha')
        expect(rendered_page).to have_checked_field('Yes')

        rows = rendered_page.all('#other-permissions-table tbody tr')
        expect(rows.map { |row| row.all('td')[0..3].map { |cell| cell.text.strip } }).to eq(
          [['Restricted collection', 'druid:bc123df4567', 'Collection', 'Read restricted']]
        )
      end
    end

    context 'when signed in as a non-admin user' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'returns unauthorized' do
        get edit_admin_workgroup_permission_path('sdr:alpha')

        expect(response).to be_unauthorized
      end
    end
  end

  describe 'PATCH /admin/workgroup_permissions/:workgroup' do
    context 'when signed in as an admin user' do
      let(:admin_user) { create(:user, groups: [AuthenticationHelpers::ADMIN_GROUP]) }

      before do
        sign_in(admin_user)
      end

      context 'when setting read unrestricted to yes and no permission exists yet' do
        it 'creates a read unrestricted permission and shows a toast' do
          patch admin_workgroup_permission_path('sdr:alpha'),
                params: { admin_workgroup_permission: { read_unrestricted: true } }

          expect(response).to redirect_to(admin_workgroup_permissions_path)
          expect(flash[:toast]).to eq('Permission updated')
          expect(Permission.permission_type_read_unrestricted.find_by(workgroup: 'sdr:alpha',
                                                                      target_druid: nil)).to be_present
        end
      end

      context 'when setting read unrestricted to no and a permission already exists' do
        before do
          create(:permission, :read_unrestricted, workgroup: 'sdr:alpha')
        end

        it 'deletes the read unrestricted permission and shows a toast' do
          patch admin_workgroup_permission_path('sdr:alpha'),
                params: { admin_workgroup_permission: { read_unrestricted: false } }

          expect(response).to redirect_to(admin_workgroup_permissions_path)
          expect(flash[:toast]).to eq('Permission updated')
          expect(Permission.permission_type_read_unrestricted.find_by(workgroup: 'sdr:alpha',
                                                                      target_druid: nil)).to be_nil
        end
      end
    end

    context 'when signed in as a non-admin user' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'returns unauthorized' do
        patch admin_workgroup_permission_path('sdr:alpha'),
              params: { admin_workgroup_permission: { read_unrestricted: true } }

        expect(response).to be_unauthorized
      end
    end
  end

  describe 'DELETE /admin/permissions/:id' do
    let(:permission) do
      create(:permission, :read_restricted, workgroup: 'sdr:alpha', target_druid: 'druid:bc123df4567')
    end

    context 'when signed in as an admin user' do
      let(:admin_user) { create(:user, groups: [AuthenticationHelpers::ADMIN_GROUP]) }

      before do
        sign_in(admin_user)
      end

      it 'deletes the permission and shows a toast' do
        delete admin_permission_path(permission)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        expect(response.body).to include('Permission deleted')
        expect(response.body).to include("turbo-stream action=\"remove\" target=\"#{ActionView::RecordIdentifier.dom_id(permission)}\"")
        expect(Permission.exists?(permission.id)).to be false
      end
    end

    context 'when signed in as a non-admin user' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'returns unauthorized' do
        delete admin_permission_path(permission)

        expect(response).to be_unauthorized
        expect(Permission.exists?(permission.id)).to be true
      end
    end
  end
end
