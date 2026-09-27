# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Content file sets' do
  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:content_file_set) { create(:content_file_set, content:, label: 'Original label') }
  let(:content_token) { Rails.application.message_verifier(:argo).generate(content.id, purpose: 'contents') }
  let(:destroy_params) do
    { content_file_set: { content_files_attributes: { '0' => { id: content_file.id, _destroy: 'true' } } } }
  end

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

    context 'when a file is updated' do
      let(:content_file) do
        create(:content_file, content_file_set:,
                              content_file_binary: create(:content_file_binary, content:, mime_type: 'image/tiff'))
      end

      it 'updates the access rights of the file' do
        patch content_content_file_set_path(content_token, content_file_set, counter: 0),
              params: { content_file_set: { content_files_attributes: { '0' => { id: content_file.id,
                                                                                 view: 'stanford',
                                                                                 download: 'stanford',
                                                                                 administrative: 'preserve_only' } } } }

        expect(response).to redirect_to(content_content_file_set_path(content_token, content_file_set, counter: 0))
        expect(content_file.reload).to have_attributes(view: 'stanford', download: 'stanford',
                                                       publish: false, preserve: true, shelve: false)
      end
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

    context 'when no administrative option is selected' do
      let(:content_file) do
        create(:content_file, content_file_set:, publish: false, preserve: false,
                              content_file_binary: create(:content_file_binary, content:, mime_type: 'image/tiff'))
      end

      it 're-renders the edit form with a single error for the options' do
        patch content_content_file_set_path(content_token, content_file_set, counter: 0),
              params: { content_file_set: { content_files_attributes: { '0' => { id: content_file.id } } } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body.scan('must be selected').size).to eq(1)
      end
    end

    context 'when a file is deleted' do
      let(:content_file) { create(:content_file, content_file_set:, position: 1) }

      before do
        create(:content_file, content_file_set:, position: 2,
                              content_file_binary: create(:content_file_binary, content:, filepath: 'image2.tif',
                                                                                mime_type: 'image/tiff'))
      end

      it 'redirects to show with a reload of the files sections' do
        patch content_content_file_set_path(content_token, content_file_set, counter: 0),
              params: destroy_params

        expect(response).to redirect_to(
          content_content_file_set_path(content_token, content_file_set, counter: 0, files_deleted: true)
        )
        follow_redirect!
        expect(response.body).to include('data-controller="dropzone-files-reload"')
      end
    end

    context 'when every file is deleted' do
      let(:content_file) { create(:content_file, content_file_set:) }

      it 'removes the resource and reloads the files sections' do
        patch content_content_file_set_path(content_token, content_file_set, counter: 0),
              params: destroy_params,
              headers: { 'Accept' => 'text/vnd.turbo-stream.html, text/html' }

        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        expect(response.body).to include(
          %(<turbo-stream action="replace" target="content_file_set_#{content_file_set.id}">)
        )
        expect(response.body).to include('data-controller="dropzone-files-reload"')
        expect(response.body).to include('Resource deleted')
        expect(ContentFileSet.exists?(content_file_set.id)).to be false
      end
    end
  end

  describe 'destroy' do
    before do
      create(:content_file, content_file_set:)
    end

    it 'deletes the resource and reloads the files sections' do
      delete content_content_file_set_path(content_token, content_file_set),
             headers: { 'Accept' => 'text/vnd.turbo-stream.html, text/html' }

      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include(
        %(<turbo-stream action="replace" target="content_file_set_#{content_file_set.id}">)
      )
      expect(response.body).to include('data-controller="dropzone-files-reload"')
      expect(response.body).to include('Resource deleted')
      expect(ContentFileSet.exists?(content_file_set.id)).to be false
    end

    context 'when the file set belongs to a different content' do
      let(:other_content) { create(:content, druid: 'druid:df456gh7890') }
      let(:content_token) { Rails.application.message_verifier(:argo).generate(other_content.id, purpose: 'contents') }

      it 'returns forbidden' do
        delete content_content_file_set_path(content_token, content_file_set)

        expect(response).to have_http_status(:forbidden)
        expect(ContentFileSet.exists?(content_file_set.id)).to be true
      end
    end
  end
end
