# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin object permissions' do
  let(:druid) { 'druid:bc123df4567' }
  let(:object_type) { 'APO' }
  let(:solr_doc) do
    {
      Search::Fields::ID => druid,
      Search::Fields::TITLE => 'My APO',
      Search::Fields::OBJECT_TYPES => [object_type]
    }
  end
  let(:admin_user) { create(:user, groups: [AuthenticationHelpers::ADMIN_GROUP]) }
  let(:rendered_page) { Capybara.string(response.body) }
  let(:object_permissions) { Permission.where(target_druid: druid) }

  before do
    allow(Sdr::Repository).to receive(:find_solr).and_return(solr_doc)
    allow(Sdr::Event).to receive(:create)
  end

  describe 'GET /admin/objects/:druid/permissions' do
    context 'when signed in as an admin user' do
      before do
        create(:permission, :read_restricted, workgroup: 'sdr:gamma', target_druid: druid)
        create(:permission, :edit, workgroup: 'sdr:alpha', target_druid: druid)
        create(:permission, :read_restricted, workgroup: 'sdr:other', target_druid: 'druid:xy987zz6543')
        create(:permission, :read_unrestricted, workgroup: 'sdr:beta')

        sign_in(admin_user)
        get admin_object_permissions_path(druid)
      end

      it 'renders the heading, the form, and the permissions for the object sorted by workgroup' do
        expect(response).to have_http_status(:ok)
        expect(Sdr::Repository).to have_received(:find_solr).with(druid:)

        expect(rendered_page).to have_css('h1', text: 'Edit APO permissions')
        expect(rendered_page).to have_link('APO', exact: true, href: '/objects/druid:bc123df4567')
        expect(rendered_page).to have_text('My APO')

        expect(rendered_page.all('select#admin_object_permission_workgroup option').map(&:text))
          .to eq(['Select or enter a workgroup', 'sdr:alpha', 'sdr:argo_administrators', 'sdr:beta',
                  'sdr:gamma', 'sdr:other'])
        expect(rendered_page).to have_field('Read', type: 'radio')
        expect(rendered_page).to have_field('Edit', type: 'radio')
        expect(rendered_page).to have_button('Add')

        expect(rendered_page.all('#object-permissions thead th').map { |header| header.text.strip })
          .to eq(['Workgroup', 'Permission', ''])
        rows = rendered_page.all('#object-permissions tbody tr')
        expect(rows.map { |row| row.all('td').first(2).map { |cell| cell.text.strip } })
          .to eq([%w[sdr:alpha Edit], %w[sdr:gamma Read]])
      end
    end

    context 'when the object is a collection' do
      let(:object_type) { 'collection' }

      before do
        sign_in(admin_user)
        get admin_object_permissions_path(druid)
      end

      it 'renders the collection heading and the empty message' do
        expect(rendered_page).to have_css('h1', text: 'Edit collection permissions')
        expect(rendered_page).to have_text('No permissions.')
      end
    end

    context 'when the object does not exist' do
      before do
        allow(Sdr::Repository).to receive(:find_solr).and_raise(Sdr::Repository::NotFoundResponse)
        sign_in(admin_user)
      end

      it 'returns not found' do
        get admin_object_permissions_path(druid)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when signed in as a non-admin user' do
      before do
        sign_in(create(:user))
      end

      it 'returns unauthorized' do
        get admin_object_permissions_path(druid)

        expect(response).to be_unauthorized
      end
    end
  end

  describe 'POST /admin/objects/:druid/permissions' do
    let(:params) { { admin_object_permission: { workgroup: 'sdr:alpha', permission_type: 'edit' } } }

    context 'when signed in as an admin user' do
      before do
        sign_in(admin_user)
      end

      it 'creates the permission and redirects to the permissions with a toast' do
        post(admin_object_permissions_path(druid), params:)

        expect(response).to redirect_to(admin_object_permissions_path(druid))
        expect(response).to have_http_status(:see_other)
        expect(flash[:toast]).to eq('Permission added')
        expect(object_permissions.pluck(:workgroup, :permission_type))
          .to eq([%w[sdr:alpha edit]])
      end

      it 'ignores a submitted target druid' do
        post admin_object_permissions_path(druid),
             params: { admin_object_permission: { workgroup: 'sdr:alpha', permission_type: 'edit',
                                                  target_druid: 'druid:xy987zz6543' } }

        expect(Permission.where.not(target_druid: nil).pluck(:target_druid)).to eq([druid])
      end

      context 'when the permission already exists' do
        before do
          create(:permission, :edit, workgroup: 'sdr:alpha', target_druid: druid)
        end

        it 'does not create the permission and renders the page with errors' do
          post(admin_object_permissions_path(druid), params:)

          expect(response).to have_http_status(:unprocessable_content)
          expect(object_permissions.count).to eq(1)
          expect(rendered_page).to have_css('h1', text: 'Edit APO permissions')
          expect(rendered_page).to have_css('.invalid-feedback', text: 'already has this permission')
          expect(rendered_page).to have_css('#object-permissions tbody tr', count: 1)
          expect(flash[:toast]).to be_nil
        end
      end

      context 'when the workgroup has a different permission for the object' do
        before do
          create(:permission, :read_restricted, workgroup: 'sdr:alpha', target_druid: druid)
        end

        it 'creates the permission as a separate row' do
          post(admin_object_permissions_path(druid), params:)

          expect(response).to redirect_to(admin_object_permissions_path(druid))
          expect(object_permissions.order(:permission_type).pluck(:workgroup, :permission_type))
            .to eq([%w[sdr:alpha edit], %w[sdr:alpha read_restricted]])
        end
      end

      context 'when the workgroup is missing' do
        let(:params) { { admin_object_permission: { workgroup: '', permission_type: 'edit' } } }

        it 'does not create the permission and renders the page with errors' do
          post(admin_object_permissions_path(druid), params:)

          expect(response).to have_http_status(:unprocessable_content)
          expect(object_permissions.count).to eq(0)
          expect(rendered_page).to have_css('.invalid-feedback', text: "can't be blank")
        end
      end
    end

    context 'when signed in as a non-admin user' do
      before do
        sign_in(create(:user))
      end

      it 'returns unauthorized and does not create the permission' do
        post(admin_object_permissions_path(druid), params:)

        expect(response).to be_unauthorized
        expect(object_permissions.count).to eq(0)
      end
    end
  end

  describe 'DELETE /admin/objects/:druid/permissions/:id' do
    let!(:permission) { create(:permission, :edit, workgroup: 'sdr:alpha', target_druid: druid) }

    context 'when signed in as an admin user' do
      before do
        sign_in(admin_user)
      end

      it 'deletes the permission and redirects to the permissions with a toast' do
        delete admin_object_permission_path(druid, permission)

        expect(response).to redirect_to(admin_object_permissions_path(druid))
        expect(response).to have_http_status(:see_other)
        expect(flash[:toast]).to eq('Permission deleted')
        expect(Permission.exists?(permission.id)).to be false
      end

      context 'when the permission belongs to a different object' do
        let!(:other_permission) do
          create(:permission, :edit, workgroup: 'sdr:alpha', target_druid: 'druid:xy987zz6543')
        end

        it 'returns not found and does not delete the permission' do
          delete admin_object_permission_path(druid, other_permission)

          expect(response).to have_http_status(:not_found)
          expect(Permission.exists?(other_permission.id)).to be true
        end
      end

      context 'when the permission is not a read or edit permission' do
        let!(:other_permission) { create(:permission, :admin, workgroup: 'sdr:alpha', target_druid: druid) }

        it 'returns not found and does not delete the permission' do
          delete admin_object_permission_path(druid, other_permission)

          expect(response).to have_http_status(:not_found)
          expect(Permission.exists?(other_permission.id)).to be true
        end
      end
    end

    context 'when signed in as a non-admin user' do
      before do
        sign_in(create(:user))
      end

      it 'returns unauthorized and does not delete the permission' do
        delete admin_object_permission_path(druid, permission)

        expect(response).to be_unauthorized
        expect(Permission.exists?(permission.id)).to be true
      end
    end
  end
end
