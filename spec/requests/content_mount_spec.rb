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
    end
  end

  describe 'create' do
    context 'with a mount path' do
      let(:mount_path) { Dir.mktmpdir(nil, Rails.root.join('tmp')) }

      after do
        FileUtils.rm_rf(mount_path)
      end

      it 'starts discovery and refreshes the page, which then shows that files are being discovered' do
        post content_mount_path(content_id: content_token), params: { mount: { path: mount_path } }

        expect(response.body).to include('<turbo-stream action="refresh"')
        expect(content.reload.mount_state).to eq('discovering')
        expect(DiscoverFilesJob).to have_been_enqueued.with(content:, mount_path:)
      end

      context 'when the content is busy' do
        let(:content) { create(:content, druid: 'druid:bc123df4567', structuring_state: 'structuring') }

        it 'refreshes the page without starting discovery' do
          post content_mount_path(content_id: content_token), params: { mount: { path: mount_path } }

          expect(response.body).to include('<turbo-stream action="refresh"')
          expect(content.reload.mount_state).to eq('discovery_not_in_progress')
          expect(DiscoverFilesJob).not_to have_been_enqueued
        end
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
end
