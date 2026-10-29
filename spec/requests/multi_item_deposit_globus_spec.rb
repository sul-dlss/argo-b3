# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Multi-item deposit Globus' do
  let(:user) { create(:user, email_address: 'jdoe@stanford.edu') }
  let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, globus_path:) }
  let(:owner) { user }
  let(:globus_path) { nil }

  before do
    sign_in(user)
  end

  describe 'new' do
    context 'when the Globus directory has not been created' do
      it 'renders the create link button' do
        get new_multi_item_deposit_action_globus_path(multi_item_deposit_action)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Create Globus link')
        expect(response.body).to include('form="create-globus-link-form"')
        expect(response.body).to include('Creating Globus link...') # spinner, shown while submitting
        expect(response.body).not_to include('Open Globus')
      end
    end

    context 'when the Globus directory has been created' do
      let(:globus_path) { '/uploads/jdoe/2026-10-28-14-03-22-417' }

      it 'renders the Globus link' do
        get new_multi_item_deposit_action_globus_path(multi_item_deposit_action)

        expect(response.body).to include('Open Globus')
        expect(response.body)
          .to include('https://app.globus.org/file-manager?destination_id=endpoint_id&amp;destination_path=%2Fuploads%2Fjdoe%2F2026-10-28-14-03-22-417')
        expect(response.body).not_to include('Create Globus link')
      end
    end

    context 'when the multi-item deposit action belongs to another user' do
      let(:owner) { create(:user) }

      it 'redirects to root' do
        get new_multi_item_deposit_action_globus_path(multi_item_deposit_action)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'create' do
    before do
      allow(GlobusClient).to receive(:mkdir)
    end

    it 'creates the Globus directory, saves its path, and redirects to new' do
      travel_to Time.zone.local(2026, 10, 28, 14, 3, 22.417r), with_usec: true do
        post multi_item_deposit_action_globus_path(multi_item_deposit_action)
      end

      expect(GlobusClient).to have_received(:mkdir)
        .with(path: '/uploads/jdoe/2026-10-28-14-03-22-417', user_id: 'jdoe@stanford.edu', notify_email: false)
      expect(multi_item_deposit_action.reload.globus_path).to eq('/uploads/jdoe/2026-10-28-14-03-22-417')
      expect(response).to redirect_to(new_multi_item_deposit_action_globus_path(multi_item_deposit_action))
    end

    context 'when the Globus directory cannot be created' do
      before do
        allow(GlobusClient).to receive(:mkdir).and_raise(GlobusClient::ForbiddenError)
        allow(Honeybadger).to receive(:notify)
      end

      it 'renders the create link button with an error' do
        post multi_item_deposit_action_globus_path(multi_item_deposit_action)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('The Globus link could not be created.')
        expect(response.body).to include('Create Globus link')
        expect(multi_item_deposit_action.reload.globus_path).to be_nil
      end
    end

    context 'when an admin creates the Globus directory for another user' do
      let(:user) { create(:user, :admin, email_address: 'admin@stanford.edu') }
      let(:owner) { create(:user, email_address: 'jdoe@stanford.edu') }

      it 'creates the Globus directory for the owner of the deposit' do
        post multi_item_deposit_action_globus_path(multi_item_deposit_action)

        expect(GlobusClient).to have_received(:mkdir)
          .with(path: start_with('/uploads/jdoe/'), user_id: 'jdoe@stanford.edu', notify_email: false)
        expect(response).to redirect_to(new_multi_item_deposit_action_globus_path(multi_item_deposit_action))
      end
    end

    context 'when the multi-item deposit action belongs to another user' do
      let(:owner) { create(:user) }

      it 'does not create the Globus directory and redirects to root' do
        post multi_item_deposit_action_globus_path(multi_item_deposit_action)

        expect(GlobusClient).not_to have_received(:mkdir)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
