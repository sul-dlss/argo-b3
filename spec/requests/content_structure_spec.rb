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

  describe 'csv' do
    let(:content_file_set) { create(:content_file_set, content:, label: 'Page 1', file_set_type: 'page') }
    let(:content_file_binary) { create(:content_file_binary, content:, filepath: 'page_0001.tif') }

    before do
      create(:content_file, content_file_set:, content_file_binary:)
    end

    it 'sends the current structure of the content as a CSV' do
      get csv_content_structure_path(content_id: content_token)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('filename="bc123df4567_structural.csv"')
      csv = CSV.parse(response.body, headers: true)
      expect(csv.headers).to eq(StructuralCsv::Export::HEADERS)
      expect(csv.sole.to_h).to include('druid' => 'bc123df4567', 'resource_label' => 'Page 1',
                                       'resource_type' => 'page', 'filename' => 'page_0001.tif')
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

  describe 'uploading a structural CSV' do
    let(:content) { create(:content, druid:, lock: cocina_object.lock, immutable: false) }
    let(:content_file_set) { create(:content_file_set, content:, label: 'Page 1', file_set_type: 'page') }
    let(:content_file_binary) do
      create(:content_file_binary, content:, filepath: 'page_0001.tif', mime_type: 'image/tiff')
    end
    let(:csv_string) { StructuralCsv::Export.as_csv(content:).sub('Page 1', 'New label') }
    let(:csv_file) do
      Rack::Test::UploadedFile.new(StringIO.new(csv_string), 'text/csv', original_filename: 'structure.csv')
    end

    before do
      create(:content_file, content_file_set:, content_file_binary:)
    end

    def upload(params = { structural_csv: { csv_file: } })
      patch content_structure_path(content_id: content_token),
            params: { commit: ContentStructureController::CSV_VALUE, content_type: Cocina::Models::ObjectType.book,
                      **params }
    end

    it 'updates the structure and redirects to edit with a reload of the files section' do
      upload

      expect(response).to redirect_to(edit_content_structure_path(content_id: content_token, structure_changed: true,
                                                                  content_type: Cocina::Models::ObjectType.book))
      expect(content.content_file_sets.reload.sole.label).to eq('New label')
    end

    context 'when no file is uploaded' do
      it 'renders the error' do
        upload({})

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('can&#39;t be blank')
      end
    end

    context 'when a row has a different druid' do
      let(:csv_string) { StructuralCsv::Export.as_csv(content:).sub('bc123df4567', 'xy987wv6543') }

      it 'renders the error without changing the structure' do
        upload

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Row 2: Druid druid:xy987wv6543 does not match this object')
        expect(content.content_file_sets.reload.sole.label).to eq('Page 1')
      end
    end

    context 'when a row has a missing druid' do
      let(:csv_string) { StructuralCsv::Export.as_csv(content:).sub('bc123df4567', '') }

      it 'renders the error' do
        upload

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Row 2: Missing druid')
      end
    end

    context 'when the import fails' do
      let(:csv_string) { StructuralCsv::Export.as_csv(content:).sub('page_0001.tif', 'page_0002.tif') }

      it 'renders the errors without changing the structure' do
        upload

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Row 2: page_0002.tif is not an existing file (files cannot be added)')
        expect(content.content_file_sets.reload.sole.content_files.sole.content_file_binary).to eq(content_file_binary)
      end
    end
  end
end
