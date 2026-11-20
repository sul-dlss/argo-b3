# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item text extraction' do
  let(:user) { create(:user, :reader) }
  let(:druid) { 'druid:bc123df4567' }
  let(:content_type) { Cocina::Models::ObjectType.book }
  let(:cocina_object) { build(:dro_with_metadata, id: druid, title: 'My item', type: content_type, version: 2) }
  let(:version_service) { version_service_double(open?: false, openable?: true, closeable?: false, version: 2) }
  let(:rendered_page) { Capybara.string(response.body) }

  let(:opened_cocina_object) { cocina_object.new(version: 3, lock: 'opened-lock') }

  before do
    allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
    allow(Sdr::Repository).to receive(:update)
    allow(Sdr::Repository).to receive(:accession)
    allow(Sdr::VersionService).to receive_messages(new: version_service, open: opened_cocina_object)
    sign_in(user)
  end

  describe 'new' do
    context 'when the user can edit a deposited book' do
      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'renders the form with the language picker, OCR warning, and default version description' do
        get "/items/#{druid}/text_extraction/new"

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_css('h1', text: 'Extract text')
        expect(rendered_page).to have_text('My item')
        expect(rendered_page).to have_select('Search for a language', multiple: true, selected: [])
        expect(rendered_page).to have_css('.alert-info', text: 'that were generated outside SDR or that have been ' \
                                                               'corrected to comply with accessibility standards.')
        expect(rendered_page).to have_no_text('auto-generate captions')
        expect(rendered_page).to have_field('Version description', with: 'Extract text')
        expect(rendered_page).to have_link('Cancel', href: "/objects/#{druid}")
        expect(rendered_page).to have_button('Save as draft')
        expect(rendered_page).to have_button('Extract text and deposit')
      end
    end

    context 'when the user can edit a media item' do
      let(:content_type) { Cocina::Models::ObjectType.media }

      before do
        allow(Settings.feature_flags).to receive(:speech_to_text_workflow).and_return(true)
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
      end

      it 'renders the captions warning without the language picker' do
        get "/items/#{druid}/text_extraction/new"

        expect(rendered_page).to have_css('.alert-info', text: 'Do not auto-generate captions/transcripts for media ' \
                                                               'files that do not contain any speech or lyrics.')
        expect(rendered_page).to have_no_text('generated outside SDR')
        expect(rendered_page).to have_no_select('Search for a language')
      end
    end

    context 'when the item has a Draft' do
      let(:version_service) { version_service_double(version: 2, version_description: 'Fixing the title') }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it "prefills the Draft's version description" do
        get "/items/#{druid}/text_extraction/new"

        expect(rendered_page).to have_field('Version description', with: 'Fixing the title')
      end
    end

    context 'when the Draft has unsaved changes to its files' do
      let(:version_service) { version_service_double(version: 2, version_description: 'Fixing the title') }

      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        content = create(:content, :mutable, druid:, lock: cocina_object.lock)
        # A file that has not been staged is an unsaved change.
        create(:content_file_binary, content:, file_location: 'attached')
      end

      it 'offers only saving as a draft, with the reason' do
        get "/items/#{druid}/text_extraction/new"

        expect(rendered_page).to have_button('Save as draft')
        expect(rendered_page).to have_no_button('Extract text and deposit')
        expect(rendered_page).to have_text('Files have unsaved changes. Deposit from "Edit files and structure".')
      end
    end

    context 'when the item is not editable' do
      let(:version_service) { version_service_double(version: 2, assembling?: true, closeable?: false) }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'redirects to the object page with an error' do
        get "/items/#{druid}/text_extraction/new"

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:warning]).to eq('Item is not editable.')
      end
    end

    context 'when the user cannot edit the item' do
      it 'redirects to the root' do
        get "/items/#{druid}/text_extraction/new"

        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
      end
    end
  end

  describe 'create' do
    let(:languages) { %w[English French] }
    let(:form_params) { { version_description: 'Run OCR', ocr_languages: ['', *languages] } }

    context 'when depositing a deposited book' do
      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'opens a new version and starts accessioning with OCR' do
        post "/items/#{druid}/text_extraction", params: { text_extraction: form_params, commit: 'deposit' }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('Text extraction started.')
        expect(Sdr::VersionService).to have_received(:open)
          .with(druid:, description: 'Run OCR', opening_user_name: user.sunetid)
        expect(Sdr::Repository).to have_received(:accession)
          .with(cocina_object: opened_cocina_object, user_name: user.sunetid,
                context: { runOCR: true, ocrLanguages: %w[English French] })
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when depositing a Draft' do
      let(:version_service) { version_service_double(version: 2, version_description: 'Fixing the title') }

      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        create(:content, :mutable, druid:, lock: cocina_object.lock)
      end

      it 'updates the version description and accessions the Draft, deleting its mutable Content' do
        post "/items/#{druid}/text_extraction", params: { text_extraction: form_params, commit: 'deposit' }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::VersionService).not_to have_received(:open)
        expect(version_service).to have_received(:update_description)
          .with(description: 'Run OCR', user_name: user.sunetid)
        expect(Sdr::Repository).to have_received(:accession)
          .with(cocina_object:, user_name: user.sunetid, context: { runOCR: true, ocrLanguages: %w[English French] })
        expect(Content.where(druid:, immutable: false)).to be_empty
      end
    end

    context 'when depositing a media item' do
      let(:content_type) { Cocina::Models::ObjectType.media }
      let(:form_params) { { version_description: 'Extract text' } }

      before do
        allow(Settings.feature_flags).to receive(:speech_to_text_workflow).and_return(true)
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
      end

      it 'starts accessioning with speech to text' do
        post "/items/#{druid}/text_extraction", params: { text_extraction: form_params, commit: 'deposit' }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::Repository).to have_received(:accession)
          .with(cocina_object: opened_cocina_object, user_name: user.sunetid, context: { runSpeechToText: true })
      end
    end

    context 'when saving a deposited book as a draft' do
      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'opens a new version and saves the OCR settings to the mutable Content for the new lock' do
        post "/items/#{druid}/text_extraction", params: { text_extraction: form_params, commit: 'draft' }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('Text extraction will run when the item is deposited.')
        expect(Sdr::VersionService).to have_received(:open)
          .with(druid:, description: 'Run OCR', opening_user_name: user.sunetid)
        expect(Sdr::Repository).not_to have_received(:accession)
        expect(Content.find_by(druid:, immutable: false))
          .to have_attributes(lock: 'opened-lock', perform_ocr: true, ocr_languages: %w[English French])
      end
    end

    context 'when saving a Draft whose files have unsaved changes as a draft' do
      let(:version_service) { version_service_double(version: 2, version_description: 'Fixing the title') }
      let!(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock) }

      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        create(:content_file_binary, content:, file_location: 'attached')
      end

      it 'saves the OCR settings to the mutable Content, keeping the unsaved changes' do
        post "/items/#{druid}/text_extraction", params: { text_extraction: form_params, commit: 'draft' }

        expect(response).to redirect_to(object_path(druid))
        expect(content.reload).to have_attributes(perform_ocr: true, ocr_languages: %w[English French])
        expect(content.content_file_binaries.count).to eq(1)
      end
    end

    context 'when depositing a Draft whose files have unsaved changes' do
      let(:version_service) { version_service_double(version: 2, version_description: 'Fixing the title') }

      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        content = create(:content, :mutable, druid:, lock: cocina_object.lock)
        create(:content_file_binary, content:, file_location: 'attached')
      end

      it 'renders the page with the error without depositing' do
        post "/items/#{druid}/text_extraction", params: { text_extraction: form_params, commit: 'deposit' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_css('.alert-danger', text: 'Files have unsaved changes.')
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when no language is chosen' do
      let(:form_params) { { version_description: 'Run OCR', ocr_languages: [''] } }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'renders the page with the error without saving' do
        post "/items/#{druid}/text_extraction", params: { text_extraction: form_params, commit: 'deposit' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_css('.invalid-feedback', text: 'Choose at least one language.')
        expect(Sdr::VersionService).not_to have_received(:open)
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when the version description is blank' do
      let(:form_params) { { version_description: '', ocr_languages: languages } }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'renders the page with the error without saving' do
        post "/items/#{druid}/text_extraction", params: { text_extraction: form_params, commit: 'deposit' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_css('#text_extraction_version_description_error')
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when other attributes of the item are submitted' do
      let(:form_params) { { version_description: 'Run OCR', ocr_languages: languages, title: 'Changed title' } }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'does not change them' do
        post "/items/#{druid}/text_extraction", params: { text_extraction: form_params, commit: 'deposit' }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when the mutable Content is busy' do
      let(:version_service) { version_service_double(version: 2, version_description: 'Fixing the title') }

      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        create(:content, :mutable, druid:, lock: cocina_object.lock, staging_state: 'staging')
      end

      it 'redirects to the object page with a warning without saving' do
        post "/items/#{druid}/text_extraction", params: { text_extraction: form_params, commit: 'deposit' }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:warning]).to eq('Files for this item are being staged, discovered, or structured. ' \
                                      'Try again when that has finished.')
        expect(version_service).not_to have_received(:update_description)
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when saving to SDR fails' do
      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        allow(Sdr::VersionService).to receive(:open).and_raise(Sdr::VersionService::Error, 'Opening version failed')
      end

      it 'renders the page with an error without depositing' do
        post "/items/#{druid}/text_extraction", params: { text_extraction: form_params, commit: 'deposit' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_css('.alert-danger', text: 'Text extraction could not be started. Try again, ' \
                                                                 'or contact SDR support if the problem continues.')
        expect(rendered_page).to have_field('Version description', with: 'Run OCR')
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when the user cannot edit the item' do
      it 'redirects to the root without saving' do
        post "/items/#{druid}/text_extraction", params: { text_extraction: form_params, commit: 'deposit' }

        expect(response).to redirect_to(root_path)
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end
  end
end
