# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Content globus' do
  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:content_token) { Rails.application.message_verifier(:argo).generate(content.id, purpose: 'contents') }
  let(:user) { create(:user, email_address: 'jdoe@stanford.edu') }
  let(:local_path) { File.join(Settings.globus.directory, 'uploads/jdoe/objects/bc123df4567') }

  before do
    sign_in(user)
  end

  after do
    FileUtils.rm_rf(Settings.globus.directory)
  end

  describe 'new' do
    let(:writable) { false }

    before do
      allow(GlobusClient).to receive(:writable?).and_return(writable)
    end

    context 'when the user cannot write to the Globus directory' do
      it 'renders the create link button' do
        get new_content_globus_path(content_id: content_token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Create Globus link')
        expect(response.body).to include('Creating Globus link...') # spinner, shown while submitting
        expect(response.body).not_to include('Discover files')
      end
    end

    context 'when the user can write to the Globus directory' do
      let(:writable) { true }

      it 'renders the Globus link and the discover button' do
        get new_content_globus_path(content_id: content_token)

        expect(response.body).to include('Open Globus')
        expect(response.body)
          .to include('https://app.globus.org/file-manager?destination_id=endpoint_id&amp;destination_path=%2Fuploads%2Fjdoe%2Fobjects%2Fbc123df4567')
        expect(response.body).to include('Discover files')
        expect(response.body).not_to include('Create Globus link')
      end
    end

    context 'when files have just been discovered' do
      it 'renders the reload of the files sections' do
        get new_content_globus_path(content_id: content_token, files_discovered: true)

        expect(response.body).to include('data-controller="frame-reloader"')
      end
    end
  end

  describe 'create' do
    let(:globus_directory) { instance_double(GlobusDirectory, create: created) }
    let(:created) { true }

    before do
      allow(GlobusDirectory).to receive(:new).and_return(globus_directory)
    end

    it 'creates the Globus directory and redirects to new' do
      post content_globus_path(content_id: content_token)

      expect(GlobusDirectory).to have_received(:new).with(druid: 'druid:bc123df4567', user:)
      expect(globus_directory).to have_received(:create)
      expect(response).to redirect_to(new_content_globus_path(content_id: content_token))
    end

    context 'when the Globus directory cannot be created' do
      let(:created) { false }

      it 'renders the create link button with an error' do
        post content_globus_path(content_id: content_token)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('The Globus link could not be created.')
        expect(response.body).to include('Create Globus link')
      end
    end
  end

  describe 'discover' do
    it 'starts discovery of the Globus directory and redirects to show' do
      post discover_content_globus_path(content_id: content_token)

      expect(response).to redirect_to(content_globus_path(content_id: content_token, discovery_started: true))
      expect(content.reload.mount_state).to eq('discovering')
      expect(DiscoverFilesJob).to have_been_enqueued.with(content:, mount_path: local_path, file_location: :globus)
    end
  end

  describe 'show' do
    context 'when discovery is in progress' do
      let(:content) { create(:content, druid: 'druid:bc123df4567', mount_state: 'discovering') }

      it 'renders the spinner, which reloads the frame' do
        get content_globus_path(content_id: content_token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Discovering files...')
        expect(response.body).to include(%(data-frame-reload-url-value="/contents/#{content_token}/globus"))
      end
    end

    context 'when discovery is not in progress' do
      it 'redirects to new with a toast' do
        get content_globus_path(content_id: content_token)

        expect(response).to redirect_to(new_content_globus_path(content_id: content_token, files_discovered: true))
        expect(flash[:toast]).to eq('Completed discovering files')
      end
    end
  end
end
