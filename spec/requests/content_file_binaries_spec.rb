# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Content file binaries' do
  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:content_file_binary) { create(:content_file_binary, content:) }
  let(:content_token) { Rails.application.message_verifier(:argo).generate(content.id, purpose: 'contents') }
  let(:headers) { { 'Accept' => 'text/vnd.turbo-stream.html, text/html' } }

  before do
    sign_in(create(:user))
  end

  describe 'destroy' do
    it 'deletes the binary and reloads the files sections with a toast' do
      delete(content_content_file_binary_path(content_token, content_file_binary), headers:)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include(%(<turbo-stream action="append" target="show_content_#{content.id}">))
      expect(response.body).to include('data-controller="dropzone-files-reload"')
      expect(response.body).to include('File deleted')
      expect(ContentFileBinary.exists?(content_file_binary.id)).to be false
    end

    context 'when the binary belongs to a different content' do
      let(:other_content) { create(:content, druid: 'druid:df456gh7890') }
      let(:content_token) { Rails.application.message_verifier(:argo).generate(other_content.id, purpose: 'contents') }

      it 'returns forbidden' do
        delete(content_content_file_binary_path(content_token, content_file_binary), headers:)

        expect(response).to have_http_status(:forbidden)
        expect(ContentFileBinary.exists?(content_file_binary.id)).to be true
      end
    end

    context 'when discovering files' do
      let(:content) { create(:content, druid: 'druid:bc123df4567', mount_state: 'discovering') }

      it 'does not delete the binary and reloads the files sections without a toast' do
        delete(content_content_file_binary_path(content_token, content_file_binary), headers:)

        expect(response).to have_http_status(:conflict)
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        expect(response.body).to include('data-controller="dropzone-files-reload"')
        expect(response.body).not_to include('File deleted')
        expect(ContentFileBinary.exists?(content_file_binary.id)).to be true
      end
    end
  end
end
