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

      expect(response.body).not_to include('data-controller="frame-reloader"')
    end

    context 'when the structure has just changed' do
      it 'reloads the files section' do
        get edit_content_structure_path(content_id: content_token, structure_changed: true)

        expect(response.body).to include('data-controller="frame-reloader"')
        expect(response.body)
          .to include(%(data-frame-reloader-reloadable-frame-outlet="#show_content_#{content.id}"))
      end
    end
  end

  describe 'edit with a structure' do
    before do
      create(:content_file, content_file_set: create(:content_file_set, content:))
    end

    it 'renders the structure validation frame for the selected content type' do
      get edit_content_structure_path(content_id: content_token, content_type: Cocina::Models::ObjectType.book)

      frame = response.parsed_body.at_css("turbo-frame#structure-validation_content_#{content.id}")
      expect(frame['refresh']).to eq('morph')
      expect(frame['src']).to eq(validation_content_structure_path(
                                   content_id: content_token, content_type: 'https://cocina.sul.stanford.edu/models/book'
                                 ))
    end

    it 'renders the delete all button, which confirms and reloads the page' do
      get edit_content_structure_path(content_id: content_token)

      form = response.parsed_body.css(%(form[action="#{content_structure_path(content_id: content_token)}"]))
                     .find { |candidate| candidate.at_css('input[name="_method"][value="delete"]') }
      expect(form['data-turbo-frame']).to eq('_top')
      expect(form['data-turbo-confirm']).to eq('Are you sure you want to delete all files and resources?')
      button = form.at_css('button.btn-link.text-danger')
      expect(button.text.strip).to eq('Delete all files and resources')
      expect(button.at_css('i.bi.bi-trash[aria-hidden="true"]')).to be_present
    end

    it 'renders the CSV upload with an unchecked allow files to be deleted checkbox' do
      get edit_content_structure_path(content_id: content_token)

      checkbox = response.parsed_body.at_css('input[type="checkbox"][name="structural_csv[allow_file_deletion]"]')
      expect(checkbox['checked']).to be_nil
      expect(response.parsed_body.at_css("label[for=\"#{checkbox['id']}\"]").text.strip)
        .to eq('Allow files to be deleted')
    end
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

    it 'deletes all of the files and resources and returns to the edit page with a toast' do
      delete content_structure_path(content_id: content_token)

      expect(response).to redirect_to(edit_content_path(druid))
      expect(flash[:toast]).to eq('All files and resources deleted')
      expect(content.content_file_binaries.reload).to be_empty
      expect(content.content_file_sets.reload).to be_empty
      expect(ContentFile.count).to eq(0)
      expect(ContentFileBinary.exists?(other_binary.id)).to be true
    end

    context 'when discovering files' do
      let(:content) { create(:content, druid:, lock: cocina_object.lock, mount_state: 'discovering') }

      it 'does not delete and returns to the edit page with an error' do
        delete content_structure_path(content_id: content_token)

        expect(response).to redirect_to(edit_content_path(druid))
        expect(flash[:danger]).to eq('Files are being discovered. Try again when discovery has finished.')
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
      it 'renders the violations as warnings' do
        get validation_content_structure_path(content_id: content_token,
                                              contents_item: { access_view: 'dark', access_download: 'none' })

        expect(response.body).not_to include('Content errors')
        expect(response.body).to include('Content warnings')
      end
    end

    context 'when dark' do
      let(:access) { { view: 'dark', download: 'none' } }

      it 'renders the violations as warnings' do
        get validation_content_structure_path(content_id: content_token)

        expect(response.body).not_to include('Content errors')
        expect(response.body).to include('Content warnings')
        expect(response.body).to include('Resource 1 (Page 1) has more than one published JP2 file.')
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

  describe 'editing with selected access' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.image)
        .new(access: { view: 'world', download: 'world' })
    end

    before do
      create(:content_file_binary, content:, filepath: 'image_0001.tif', mime_type: 'image/tiff')
    end

    it 'uses the selected access to select the populator and keeps it for structuring' do
      get edit_content_structure_path(content_id: content_token,
                                      contents_item: { with_embargo: false, access_view: 'dark',
                                                       access_download: 'none' })

      # A dark object is not structured as an image.
      expect(response.body).to include('Strategy for structuring: Default (resource per file)')
      form = response.parsed_body.at_css(%(form[action="#{content_structure_path(content_id: content_token)}"]))
      expect(form.at_css('input[name="contents_item[access_view]"]')['value']).to eq('dark')
    end
  end

  describe 'updating with selected access' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid).new(access: { view: 'world', download: 'world' }) }
    let(:selected_access) { { 'with_embargo' => 'false', 'access_view' => 'dark', 'access_download' => 'none' } }

    before do
      create(:content_file_binary, content:, filepath: 'document.pdf', mime_type: 'application/pdf')
    end

    it 'structures the files with the selected access and redirects to edit with it' do
      patch content_structure_path(content_id: content_token),
            params: { commit: ContentStructureController::STRUCTURE_VALUE, populator: 'FileSetPerFile',
                      contents_item: selected_access }

      expect(response).to redirect_to(edit_content_structure_path(content_id: content_token, structure_changed: true,
                                                                  contents_item: selected_access))
      expect(content.content_files.sole).to have_attributes(view: 'dark', download: 'none', preserve: true,
                                                            shelve: false, publish: false)
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
    let(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock) }
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

    def allow_file_deletion_checkbox
      response.parsed_body.at_css('input[type="checkbox"][name="structural_csv[allow_file_deletion]"]')
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

    context 'when a file would be deleted' do
      let!(:omitted_content_file_binary) do
        create(:content_file_binary, content:, filepath: 'page_0002.tif', mime_type: 'image/tiff')
      end

      it 'renders the error without deleting the file, keeping the checkbox unchecked' do
        upload

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Files would be deleted: page_0002.tif. ' \
                                         'Select &quot;Allow files to be deleted&quot; to delete them.')
        expect(ContentFileBinary.exists?(omitted_content_file_binary.id)).to be true
        expect(allow_file_deletion_checkbox['checked']).to be_nil
      end

      context 'when deletion is allowed' do
        it 'deletes the file' do
          upload({ structural_csv: { csv_file:, allow_file_deletion: '1' } })

          expect(response).to have_http_status(:redirect)
          expect(ContentFileBinary.exists?(omitted_content_file_binary.id)).to be false
          expect(content.content_file_sets.reload.sole.label).to eq('New label')
        end
      end

      context 'when deletion is allowed but the CSV has other errors' do
        let(:csv_string) { StructuralCsv::Export.as_csv(content:).sub('bc123df4567', '') }

        it 'renders the errors, keeping the checkbox checked' do
          upload({ structural_csv: { csv_file:, allow_file_deletion: '1' } })

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include('Row 2: Missing druid')
          expect(allow_file_deletion_checkbox['checked']).to eq('checked')
        end
      end
    end
  end
end
