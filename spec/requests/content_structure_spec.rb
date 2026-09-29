# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Content structure' do
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:content) { create(:content, druid:, lock: cocina_object.lock) }
  let(:content_token) { Rails.application.message_verifier(:argo).generate(content.id, purpose: 'contents') }

  before do
    allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
    sign_in(create(:user))
  end

  describe 'edit' do
    it 'does not reload the files section' do
      get edit_content_structure_path(content_id: content_token)

      expect(response.body).not_to include('data-controller="dropzone-files-reload"')
    end

    context 'when the structure has just changed' do
      it 'reloads the files section' do
        get edit_content_structure_path(content_id: content_token, structure_changed: true)

        expect(response.body).to include('data-controller="dropzone-files-reload"')
        expect(response.body)
          .to include(%(data-dropzone-files-reload-dropzone-files-outlet="#show_content_#{content.id}"))
      end
    end
  end

  describe 'updating' do
    it 'redirects to edit with a reload of the files section' do
      patch content_structure_path(content_id: content_token),
            params: { commit: ContentStructureController::STRUCTURE_VALUE, populator: 'FileSetPerFile' }

      expect(response).to redirect_to(edit_content_structure_path(content_id: content_token, structure_changed: true))
    end
  end

  describe 'editing with a selected content type' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid).new(access: { view: 'world', download: 'world' })
    end

    before do
      create(:content_file_binary, content:, filepath: 'page_0001.tif', mime_type: 'image/tiff')
    end

    it 'uses the populator for the selected content type' do
      get edit_content_structure_path(content_id: content_token, content_type: Cocina::Models::ObjectType.book)

      expect(response.body).to include('Strategy for structuring: Book (resource per page)')
    end
  end

  describe 'updating with a selected content type' do
    it 'redirects to edit with the selected content type' do
      patch content_structure_path(content_id: content_token),
            params: { commit: ContentStructureController::STRUCTURE_VALUE, populator: 'FileSetPerFile',
                      content_type: Cocina::Models::ObjectType.book }

      expect(response).to redirect_to(edit_content_structure_path(content_id: content_token, structure_changed: true,
                                                                  content_type: Cocina::Models::ObjectType.book))
    end
  end

  describe 'updating with an unknown populator' do
    it 'returns bad request' do
      patch content_structure_path(content_id: content_token),
            params: { commit: ContentStructureController::STRUCTURE_VALUE, populator: 'Base' }

      expect(response).to have_http_status(:bad_request)
    end
  end
end
