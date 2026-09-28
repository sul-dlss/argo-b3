# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Content file sets' do
  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:content_file_set) { create(:content_file_set, content:, label: 'Original label') }
  let(:content_token) { Rails.application.message_verifier(:argo).generate(content.id, purpose: 'contents') }

  before do
    sign_in(create(:user))
  end

  describe 'update' do
    it 'updates the file set and redirects to show with a toast' do
      patch content_content_file_set_path(content_token, content_file_set, counter: 0),
            params: { content_file_set: { label: 'New label', file_set_type: 'image' } }

      expect(response).to redirect_to(content_content_file_set_path(content_token, content_file_set, counter: 0))
      expect(flash[:toast]).to eq('Resource updated')
      content_file_set.reload
      expect(content_file_set.label).to eq('New label')
      expect(content_file_set.file_set_type).to eq('image')
    end

    context 'when the file set belongs to a different content' do
      let(:other_content) { create(:content, druid: 'druid:df456gh7890') }
      let(:content_token) { Rails.application.message_verifier(:argo).generate(other_content.id, purpose: 'contents') }

      it 'returns forbidden' do
        patch content_content_file_set_path(content_token, content_file_set, counter: 0),
              params: { content_file_set: { label: 'New label' } }

        expect(response).to have_http_status(:forbidden)
        expect(content_file_set.reload.label).to eq('Original label')
      end
    end

    context 'when the update is invalid' do
      let(:content_file) { create(:content_file, content_file_set:) }

      it 're-renders the edit form' do
        patch content_content_file_set_path(content_token, content_file_set, counter: 0),
              params: { content_file_set: { label: 'New label',
                                            content_files_attributes: { '0' => { id: content_file.id,
                                                                                 mime_type: ' ' } } } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Save')
        expect(flash[:toast]).to be_nil
        expect(content_file_set.reload.label).to eq('Original label')
      end
    end
  end
end
