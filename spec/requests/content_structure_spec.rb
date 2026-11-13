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

  describe 'destroy' do
    let(:other_binary) { create(:content_file_binary, content: create(:content, druid: 'druid:df456gh7890')) }

    before do
      structured_binary = create(:content_file_binary, content:, filepath: 'structured.txt')
      create(:content_file, content_file_set: create(:content_file_set, content:),
                            content_file_binary: structured_binary)
      create(:content_file_binary, content:, filepath: 'unassociated.txt') # Not in a resource
      create(:content_file_set, content:) # A resource without files
      other_binary
    end

    it 'deletes all of the files and resources and returns to the add and edit files step with a toast' do
      content.update!(step: 'structure')
      delete content_structure_path(content_id: content_token)

      expect(response).to redirect_to(edit_content_path(druid))
      expect(flash[:toast]).to eq('All files and resources deleted')
      expect(content.reload.step).to eq('files')
      expect(content.content_file_binaries.reload).to be_empty
      expect(content.content_file_sets.reload).to be_empty
      expect(ContentFile.count).to eq(0)
      expect(ContentFileBinary.exists?(other_binary.id)).to be true
    end

    context 'when discovering files' do
      let(:content) { create(:content, druid:, lock: cocina_object.lock, mount_state: 'discovering') }

      it 'does not delete and returns to the edit page with a warning' do
        delete content_structure_path(content_id: content_token)

        expect(response).to redirect_to(edit_content_path(druid))
        expect(flash[:warning]).to eq('Files are being staged, discovered, or structured. ' \
                                      'Try again when that has finished.')
        expect(content.content_file_binaries.count).to eq(2)
        expect(content.content_file_sets.count).to eq(2)
      end
    end
  end

  describe 'validation' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book).new(access:)
    end
    let(:access) { { view: 'world', download: 'world' } }
    let(:content_file_set) { create(:content_file_set, content:, label: 'Page 1', file_set_type: 'page') }

    before do
      create(:content_file, content_file_set:, position: 1,
                            content_file_binary: create(:content_file_binary, content:, filepath: 'page_0001.jp2',
                                                                              mime_type: 'image/jp2'))
      create(:content_file, content_file_set:, position: 2,
                            content_file_binary: create(:content_file_binary, content:, filepath: 'page_0001a.jp2',
                                                                              mime_type: 'image/jp2'))
    end

    it 'renders the errors' do
      get validation_content_structure_path(content_id: content_token)

      expect(response.body).to include(%(<turbo-frame id="structure-validation_content_#{content.id}"))
      expect(response.body).to include('Content errors')
      expect(response.body).not_to include('Content warnings')
      expect(response.body).to include('Resource 1 (Page 1) has more than one published JP2 file.')
    end

    context 'when dark access is selected' do
      before do
        content.update!(content_type: Cocina::Models::ObjectType.book, access_view: 'dark', access_download: 'none')
      end

      it 'renders the violations as warnings' do
        get validation_content_structure_path(content_id: content_token)

        expect(response.body).not_to include('Content errors')
        expect(response.body).to include('Content warnings')
      end
    end

    context 'when dark' do
      let(:access) { { view: 'dark', download: 'none' } }

      it 'renders the violations as warnings and the files that are not dark as errors' do
        get validation_content_structure_path(content_id: content_token)

        expect(response.body).to include('Content warnings')
        expect(response.body).to include('Resource 1 (Page 1) has more than one published JP2 file.')
        expect(response.body).to include('Content errors')
        expect(response.body)
          .to include('Resource 1 (Page 1) file page_0001.jp2 must not be published or shelved ' \
                      'because the object is dark.')
      end
    end

    context 'when citation-only' do
      let(:access) { { view: 'citation-only', download: 'none' } }

      it 'renders the violations as warnings' do
        get validation_content_structure_path(content_id: content_token)

        expect(response.body).not_to include('Content errors')
        expect(response.body).to include('Content warnings')
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
end
