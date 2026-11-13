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

        link = Capybara.string(response.body).find_link('Open Globus (opens in new tab)')
        expect(link[:href])
          .to eq('https://app.globus.org/file-manager?destination_id=endpoint_id&destination_path=%2Fuploads%2Fjdoe%2Fobjects%2Fbc123df4567')
        expect(link[:target]).to eq('_blank')
        expect(link).to have_css('i.bi-box-arrow-up-right[aria-hidden="true"]')
        expect(response.body).to include('Discover files')
        expect(response.body).not_to include('Create Globus link')
      end
    end
  end

  describe 'create' do
    let(:globus_directory) { instance_double(GlobusDirectory, create: created) }
    let(:created) { true }

    before do
      allow(GlobusDirectory).to receive(:for_object).and_return(globus_directory)
    end

    it 'creates the Globus directory and redirects to new' do
      post content_globus_path(content_id: content_token)

      expect(GlobusDirectory).to have_received(:for_object).with(druid: 'druid:bc123df4567', user:)
      expect(globus_directory).to have_received(:create)
      expect(response).to redirect_to(new_content_globus_path(content_id: content_token))
    end

    context 'when the Globus directory cannot be created' do
      let(:created) { false }

      it 'renders the create link button with an error' do
        post content_globus_path(content_id: content_token)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Create Globus link')
        page = Capybara.string(response.body)
        expect(page).to have_css('.alert-danger[role="alert"]', text: 'The Globus link could not be created.')
      end
    end
  end

  describe 'discover' do
    it 'starts discovery of the Globus directory and refreshes the page' do
      post discover_content_globus_path(content_id: content_token)

      expect(response.body).to include('<turbo-stream action="refresh"')
      expect(content.reload.mount_state).to eq('discovering')
      expect(DiscoverFilesJob).to have_been_enqueued.with(content:, mount_path: local_path, file_location: :globus)
    end
  end
end
