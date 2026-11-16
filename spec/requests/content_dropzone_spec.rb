# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Content dropzone' do
  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:content_token) { Rails.application.message_verifier(:argo).generate(content.id, purpose: 'contents') }
  let(:file) { fixture_file_upload('dropzone_upload.txt', 'text/plain') }

  before do
    sign_in(create(:user))
  end

  describe 'update' do
    it 'adds the uploaded file' do
      patch content_dropzone_path(content_id: content_token),
            params: { content: { files: { '0' => file }, paths: { '0' => 'dropzone_upload.txt' } } }

      expect(response).to have_http_status(:ok)
      expect(content.content_file_binaries.sole.filepath).to eq('dropzone_upload.txt')
    end

    context 'when the content is busy' do
      let(:content) { create(:content, druid: 'druid:bc123df4567', structuring_state: 'structuring') }

      it 'does not add the file' do
        patch content_dropzone_path(content_id: content_token),
              params: { content: { files: { '0' => file }, paths: { '0' => 'dropzone_upload.txt' } } }

        expect(response).to have_http_status(:conflict)
        expect(content.content_file_binaries).to be_empty
      end
    end
  end
end
