# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin object permissions' do
  let(:user) { create(:user, groups: [AuthenticationHelpers::ADMIN_GROUP]) }
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:collection_with_metadata, id: druid) }
  let(:rendered_page) { Capybara.string(response.body) }

  before do
    allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
    sign_in(user)
  end

  describe 'GET /admin/objects/:object_id/permissions' do
    it 'renders the immediate-add form and an empty object permissions table' do
      create(:permission, :read_unrestricted, workgroup: 'sdr:zeta')
      create(:permission, :read_unrestricted, workgroup: 'sdr:alpha')
      get admin_object_permissions_path(druid)

      expect(response).to have_http_status(:ok)
      expect(rendered_page).to have_css('h1', text: 'Manage permissions')
      expect(rendered_page).to have_link('Return to object', href: object_path(druid))
      expect(rendered_page).to have_select('Workgroup', options: ['Select or enter a workgroup', 'sdr:alpha',
                                                                  'sdr:argo_administrators', 'sdr:zeta'])
      expect(rendered_page).to have_field('Read', type: 'radio', with: 'read_restricted')
      expect(rendered_page).to have_field('Edit', type: 'radio', with: 'edit')
      expect(rendered_page).to have_button('Add permission')
      expect(rendered_page).to have_no_button('Save')
      expect(rendered_page).to have_no_link('Cancel')
      expect(rendered_page).to have_css('th', text: 'Workgroup')
      expect(rendered_page).to have_css('th', text: 'Permission')
      expect(rendered_page).to have_text('No permissions.')
      expect(Sdr::Repository).to have_received(:find).with(druid:)
    end

    it 'normalizes a bare druid before fetching the object' do
      get admin_object_permissions_path('bc123df4567')
      expect(response).to have_http_status(:ok)
      expect(Sdr::Repository).to have_received(:find).with(druid: 'druid:bc123df4567')
    end

    context 'when the target is an APO' do
      let(:cocina_object) { build(:admin_policy_with_metadata, id: druid) }

      it 'allows management' do
        get admin_object_permissions_path(druid)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the target is a DRO' do
      let(:cocina_object) { build(:dro_with_metadata, id: druid) }

      it 'rejects management even for an admin' do
        get admin_object_permissions_path(druid)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the user is not an admin' do
      let(:user) { create(:user) }

      it 'denies access before fetching the object' do
        get admin_object_permissions_path(druid)
        expect(response).to be_unauthorized
        expect(Sdr::Repository).not_to have_received(:find)
      end
    end
  end

  it 'lists only the target permissions in workgroup order, with Read and Edit labels' do
    create(:permission, :edit, workgroup: 'sdr:zeta', target_druid: druid)
    create(:permission, :read_restricted, workgroup: 'sdr:alpha', target_druid: druid)
    create(:permission, :edit, workgroup: 'sdr:other', target_druid: 'druid:df456gh7890')
    get admin_object_permissions_path(druid)

    rows = rendered_page.all('#object-permissions-table tbody tr')
    expect(rows.map { |row| row.all('td').first(2).map { |cell| cell.text.strip } })
      .to eq([['sdr:alpha', 'Read'], ['sdr:zeta', 'Edit']])
    expect(rendered_page).to have_no_text('sdr:argo_administrators Admin')
  end

  describe 'POST /admin/objects/:object_id/permissions' do
    let(:attributes) { { workgroup: 'sdr:curators', permission_type: 'read_restricted' } }

    it 'adds the permission for the URL target and returns a toast and Turbo refresh' do
      post admin_object_permissions_path(druid),
           params: { admin_object_permission: attributes.merge(target_druid: 'druid:df456gh7890') },
           as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include('Permission added', '<turbo-stream action="refresh"')
      expect(rendered_page.all('turbo-stream').pluck(:action)).to eq(%w[update append refresh])
      expect(rendered_page).to have_css('turbo-stream[action="update"][target="object-permission-form"]')
      expect(Permission.find_by(workgroup: 'sdr:curators')&.target_druid).to eq(druid)
    end

    it 'redirects HTML submissions back to management with the exact toast' do
      post admin_object_permissions_path(druid), params: { admin_object_permission: attributes }
      expect(response).to redirect_to(admin_object_permissions_path(druid))
      expect(flash[:toast]).to eq('Permission added')
    end

    context 'when the input is invalid' do
      let(:attributes) { { workgroup: '', permission_type: 'admin' } }

      it 'shows validation feedback without creating a permission' do
        expect do
          post admin_object_permissions_path(druid), params: { admin_object_permission: attributes }, as: :turbo_stream
        end.not_to change(Permission, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_text("can't be blank")
        expect(rendered_page).to have_text('is not included in the list')
      end
    end

    context 'when the permission already exists' do
      before do
        create(:permission, :read_restricted, workgroup: 'sdr:curators', target_druid: druid)
      end

      it 'shows duplicate feedback and preserves the table' do
        expect do
          post admin_object_permissions_path(druid), params: { admin_object_permission: attributes }
        end.not_to change(Permission, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_text('already has this permission')
        expect(rendered_page).to have_css('#object-permissions-table tbody tr', count: 1)
      end
    end
  end

  describe 'DELETE /admin/objects/:object_id/permissions/:id' do
    let!(:permission) { create(:permission, :edit, workgroup: 'sdr:curators', target_druid: druid) }

    it 'deletes the permission and returns a toast and Turbo refresh' do
      delete admin_object_permission_path(druid, permission), as: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Permission deleted', '<turbo-stream action="refresh"')
      expect(Permission.exists?(permission.id)).to be false
    end

    it 'rejects a permission belonging to another object' do
      other_permission = create(:permission, :edit, target_druid: 'druid:df456gh7890')
      delete admin_object_permission_path(druid, other_permission), as: :turbo_stream
      expect(response).to have_http_status(:not_found)
      expect(Permission.exists?(other_permission.id)).to be true
    end

    it 'rejects a global admin permission' do
      global_permission = Permission.permission_type_admin.first!
      delete admin_object_permission_path(druid, global_permission), as: :turbo_stream
      expect(response).to have_http_status(:not_found)
      expect(Permission.exists?(global_permission.id)).to be true
    end
  end

  %i[get post delete].each do |verb|
    it "rejects an embedded newline on #{verb.upcase} without fetching an object" do
      path = '/admin/objects/druid:bc123df4567%0Ax/permissions'
      path += '/1' if verb == :delete
      public_send(verb, path,
                  params: { admin_object_permission: { workgroup: 'sdr:curators', permission_type: 'edit' } })
      expect(response).to have_http_status(:not_found)
      expect(Sdr::Repository).not_to have_received(:find)
    end

    it "returns 404 for a well-formed missing target on #{verb.upcase}" do
      allow(Sdr::Repository).to receive(:find).and_raise(Sdr::Repository::NotFoundResponse)
      path = verb == :delete ? admin_object_permission_path(druid, 1) : admin_object_permissions_path(druid)
      public_send(verb, path,
                  params: { admin_object_permission: { workgroup: 'sdr:curators', permission_type: 'edit' } })
      expect(response).to have_http_status(:not_found)
      expect(Sdr::Repository).to have_received(:find).with(druid: 'druid:bc123df4567')
    end

    it "rejects a malformed druid on #{verb.upcase} without fetching an object" do
      path = verb == :delete ? admin_object_permission_path('malformed', 1) : admin_object_permissions_path('malformed')
      public_send(verb, path,
                  params: { admin_object_permission: { workgroup: 'sdr:curators', permission_type: 'edit' } })
      expect(response).to have_http_status(:not_found)
      expect(Sdr::Repository).not_to have_received(:find)
    end
  end

  %i[post delete].each do |verb|
    describe "#{verb.upcase} authorization" do
      let!(:permission) { create(:permission, :edit, target_druid: druid) }
      let(:path) do
        verb == :post ? admin_object_permissions_path(druid) : admin_object_permission_path(druid, permission)
      end
      let(:attributes) { { admin_object_permission: { workgroup: 'sdr:new', permission_type: 'edit' } } }

      context 'when the user is not an admin' do
        let(:user) { create(:user) }

        it 'rejects the write without changing permissions' do
          expect { public_send(verb, path, params: attributes) }.not_to change(Permission, :count)
          expect(response).to be_unauthorized
          expect(Sdr::Repository).not_to have_received(:find)
        end
      end

      context 'when the target is a DRO' do
        let(:cocina_object) { build(:dro_with_metadata, id: druid) }

        it 'rejects the write even for an admin' do
          expect { public_send(verb, path, params: attributes) }.not_to change(Permission, :count)
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
