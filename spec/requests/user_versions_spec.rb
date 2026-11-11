# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User versions' do
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, user_version: user_version_client, version: version_client,
                                                   milestones: milestones_client)
  end
  let(:user_version_client) do
    instance_double(Dor::Services::Client::UserVersion, update: nil, inventory: user_version_inventory)
  end
  let(:version_client) do
    instance_double(Dor::Services::Client::ObjectVersion, inventory: [
                      Dor::Services::Client::ObjectVersion::Version.new(versionId: 1, message: 'Initial version'),
                      Dor::Services::Client::ObjectVersion::Version.new(versionId: 2, message: 'Second version')
                    ])
  end
  let(:milestones_client) { instance_double(Dor::Services::Client::Milestones, list: []) }
  let(:user_version_inventory) do
    [
      Dor::Services::Client::UserVersion::Version.new(version: 1, userVersion: 1, head: false, withdrawn: true,
                                                      withdrawable: false, restorable: true),
      Dor::Services::Client::UserVersion::Version.new(version: 2, userVersion: 2, head: true, withdrawn: false,
                                                      withdrawable: false, restorable: false)
    ]
  end
  let(:user) { create(:user, :reader) }
  let(:turbo_headers) { { 'Accept' => 'text/vnd.turbo-stream.html, text/html' } }

  before do
    allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in(user)
  end

  context 'when the user has edit permission' do
    before do
      create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
    end

    describe 'POST /objects/:object_druid/user_versions/:user_version/withdraw' do
      it 'withdraws the user version, shows the toast, and replaces the versions frame' do
        post "/objects/#{druid}/user_versions/1/withdraw", headers: turbo_headers

        expect(user_version_client).to have_received(:update)
          .with(user_version: Dor::Services::Client::UserVersion::Version.new(userVersion: 1, withdrawn: true))
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        expect(response.body).to include('Public version withdrawn')
        expect(response.body).not_to include('turbo-stream action="refresh"')
        expect(response.body).to include('turbo-stream action="update" target="druid:bc123df4567_versions"')
        # Capybara does not look inside the turbo stream's template, so the frame content is checked as text.
        expect(response.body).to include('id="versions-table"', '1 (withdrawn)', '>Restore</button>')
      end
    end

    describe 'POST /objects/:object_druid/user_versions/:user_version/restore' do
      it 'restores the user version, shows the toast, and replaces the versions frame' do
        post "/objects/#{druid}/user_versions/1/restore", headers: turbo_headers

        expect(user_version_client).to have_received(:update)
          .with(user_version: Dor::Services::Client::UserVersion::Version.new(userVersion: 1, withdrawn: false))
        expect(response.body).to include('Public version restored')
        expect(response.body).to include('turbo-stream action="update" target="druid:bc123df4567_versions"')
      end
    end

    context 'when updating the user version fails' do
      before do
        allow(user_version_client).to receive(:update).and_raise(Dor::Services::Client::Error, 'Oops')
      end

      it 'shows an alert in the versions frame' do
        post "/objects/#{druid}/user_versions/1/withdraw", headers: turbo_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('turbo-stream action="update" target="druid:bc123df4567_versions"')
        expect(response.body)
          .to match(/target="flash-alerts"><template>\s*<div[^>]*alert-danger.*?Updating the public version failed/m)
        expect(response.body).to include('id="versions-table"')
        expect(response.body).not_to include('Public version withdrawn')
      end
    end
  end

  context 'when the user does not have edit permission' do
    it 'does not withdraw the user version' do
      post "/objects/#{druid}/user_versions/1/withdraw"

      expect(user_version_client).not_to have_received(:update)
      expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
    end

    it 'does not restore the user version' do
      post "/objects/#{druid}/user_versions/1/restore"

      expect(user_version_client).not_to have_received(:update)
      expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
    end
  end
end
