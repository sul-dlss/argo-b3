# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Import read unrestricted workgroups bulk action' do
  let(:csv_file) { fixture_file_upload('import_read_unrestricted_workgroups.csv', 'text/csv') }
  let(:form_params) do
    {
      bulk_actions_import_read_unrestricted_workgroups: {
        csv_file:,
        description: 'Update read unrestricted workgroups'
      }
    }
  end

  context 'when signed in as an admin user' do
    let(:admin_user) { create(:user, :admin) }

    before do
      sign_in(admin_user)
    end

    it 'allows access to the new page' do
      get new_bulk_actions_import_read_unrestricted_workgroups_path

      expect(response).to have_http_status(:ok)
    end

    it 'creates the bulk action' do
      post bulk_actions_import_read_unrestricted_workgroups_path, params: form_params

      expect(response).to redirect_to(bulk_actions_path)
      expect(BulkAction.last.action_type)
        .to eq(BulkActions::IMPORT_READ_UNRESTRICTED_WORKGROUPS.action_type.to_s)
    end
  end

  context 'when signed in as a non-admin user' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    it 'does not allow access to the new page' do
      get new_bulk_actions_import_read_unrestricted_workgroups_path

      expect(response).to be_unauthorized
    end

    it 'does not create the bulk action' do
      post bulk_actions_import_read_unrestricted_workgroups_path, params: form_params

      expect(response).to be_unauthorized
      expect(BulkAction.count).to eq(0)
    end
  end
end
