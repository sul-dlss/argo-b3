# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Content mount' do
  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:content_token) { Rails.application.message_verifier(:argo).generate(content.id, purpose: 'contents') }

  before do
    sign_in(create(:user))
  end

  describe 'new' do
    it 'renders the mount form' do
      get new_content_mount_path(content_id: content_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Mount path')
      expect(response.body).not_to include('data-controller="dropzone-files-reload"')
    end

    context 'when files have just been discovered' do
      it 'renders the reload of the files sections' do
        get new_content_mount_path(content_id: content_token, files_discovered: true)

        expect(response.body).to include('data-controller="dropzone-files-reload"')
      end
    end
  end

  describe 'create' do
    context 'with a mount path' do
      let(:mount_path) { Dir.mktmpdir(nil, Rails.root.join('tmp')) }

      after do
        FileUtils.rm_rf(mount_path)
      end

      it 'starts discovery and redirects to show' do
        post content_mount_path(content_id: content_token), params: { mount: { path: mount_path } }

        expect(response).to redirect_to(content_mount_path(content_id: content_token))
        expect(content.reload.mount_state).to eq('discovering')
        expect(DiscoverFilesJob).to have_been_enqueued.with(content:, mount_path:)
      end
    end

    context 'without a mount path' do
      it 'renders the form with an error' do
        post content_mount_path(content_id: content_token), params: { mount: { path: '' } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(content.reload.mount_state).to eq('discovery_not_in_progress')
        expect(DiscoverFilesJob).not_to have_been_enqueued
      end
    end
  end

  describe 'show' do
    context 'when discovery is in progress' do
      let(:content) { create(:content, druid: 'druid:bc123df4567', mount_state: 'discovering') }

      it 'renders the spinner, which reloads the frame' do
        get content_mount_path(content_id: content_token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Discovering files...')
        expect(response.body).to include('data-controller="frame-reload"')
      end
    end

    context 'when discovery is not in progress' do
      it 'redirects to the mount form with a toast' do
        get content_mount_path(content_id: content_token)

        expect(response).to redirect_to(new_content_mount_path(content_id: content_token, files_discovered: true))
        expect(flash[:toast]).to eq('Completed discovering files')
      end
    end
  end
end
