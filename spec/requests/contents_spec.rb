# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Contents' do
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book) }
  let(:updated_cocina_object) { cocina_object.new(lock: 'updated-lock') }
  let!(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock) }
  let(:user) { create(:user) }
  # Defaults to the initial version, for which a version description is not entered.
  let(:version_service) do
    version_service_double(open?: open, editable?: editable, version:, version_description: 'Initial version')
  end
  let(:editable) { true }
  let(:open) { true }
  let(:version) { 1 }
  let(:opened_cocina_object) { cocina_object.new(version: 2, lock: 'opened-lock') }

  before do
    allow(Sdr::Repository).to receive_messages(find: cocina_object, update: updated_cocina_object,
                                               find_solr: build(:solr_item, druid:))
    allow(Sdr::VersionService).to receive_messages(new: version_service, open: opened_cocina_object)
    allow(StageFilesJob).to receive(:perform_later)
    create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
    sign_in(user)
  end

  describe 'edit' do
    context 'when the version is not editable' do
      let(:editable) { false }

      it 'redirects to the object page' do
        get edit_content_path(druid)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:warning]).to eq(I18n.t('edit.items.edit.warnings.not_editable'))
      end
    end

    context 'when the initial version' do
      it 'does not render the version description' do
        get edit_content_path(druid)

        expect(response).to have_http_status(:ok)
        expect(Capybara.string(response.body)).to have_no_field('Version description')
      end
    end

    context 'when an item' do
      it 'renders the item details tab' do
        get edit_content_path(druid)

        page = Capybara.string(response.body)
        expect(page).to have_css('[role="tab"]', text: 'Item details')
        expect(page).to have_select('Content type', visible: :all)
      end
    end

    context 'when an agreement' do
      let(:cocina_object) { build(:agreement_with_metadata, id: druid) }

      before do
        allow(Sdr::Repository).to receive(:find_solr).and_return(build(:solr_item, :agreement, druid:))
      end

      it 'does not render the item details tab' do
        get edit_content_path(druid)

        page = Capybara.string(response.body)
        expect(page).to have_css('[role="tab"]', text: 'Add files')
        expect(page).to have_no_css('[role="tab"]', text: 'Item details')
        expect(page).to have_no_select('Content type', visible: :all)
      end
    end

    context 'when the version is open' do
      let(:version) { 2 }

      it 'prefills the version description from the open version' do
        get edit_content_path(druid)

        expect(Capybara.string(response.body)).to have_field('Version description', with: 'Initial version')
        expect(Sdr::VersionService).to have_received(:new).with(druid:).once
      end
    end

    context 'when the version is closed' do
      let(:open) { false }

      it 'renders an empty version description' do
        get edit_content_path(druid)

        expect(Capybara.string(response.body).find_field('Version description').value).to be_blank
      end
    end

    context 'when OCR settings were saved with the content' do
      before { content.update!(perform_ocr: true, ocr_languages: ['English']) }

      it 'prefills them' do
        get edit_content_path(druid)

        page = Capybara.string(response.body)
        expect(page).to have_field('Yes', type: 'radio', checked: true)
        expect(page).to have_css('select option[value="English"][selected]', visible: :all)
      end
    end

    context 'when the user cannot edit the object' do
      before { Permission.permission_type_edit.destroy_all }

      it 'denies access' do
        get edit_content_path(druid)

        expect(response).to redirect_to(root_path)
        expect(flash[:warning]).to eq(I18n.t('errors.not_authorized'))
      end
    end
  end

  describe 'update' do
    context 'when depositing' do
      it 'updates the object and stages with accessioning' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { viewing_direction: 'right-to-left' } }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::Repository).to have_received(:update)
          .with(cocina_object: having_attributes(
            structural: having_attributes(hasMemberOrders: [having_attributes(viewingDirection: 'right-to-left')]),
            description: cocina_object.description
          ), user_name: user.sunetid, description: nil)
        expect(content.reload).to have_attributes(lock: 'updated-lock', staging_state: 'staging')
        expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: true, user:)
        expect(flash[:toast]).to eq(I18n.t('edit.items.new.toasts.staging_started'))
      end
    end

    context 'when depositing an agreement' do
      let(:cocina_object) { build(:agreement_with_metadata, id: druid) }

      it 'stages with accessioning' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE }

        expect(response).to redirect_to(object_path(druid))
        expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: true, user:)
        expect(flash[:toast]).to eq(I18n.t('edit.items.new.toasts.staging_started'))
      end
    end

    context 'when the content previously failed staging' do
      let!(:content) do
        create(:content, :mutable, druid:, lock: cocina_object.lock, staging_state: 'staging_failed')
      end

      it 'stages again' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { viewing_direction: 'right-to-left' } }

        expect(response).to redirect_to(object_path(druid))
        expect(content.reload.staging_state).to eq('staging')
        expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: true, user:)
      end
    end

    context 'when other content failed staging' do
      let!(:failed_content) { create(:content, druid:, lock: 'earlier-lock', staging_state: 'staging_failed') }
      let!(:other_object_failed_content) do
        create(:content, druid: 'druid:df123bc4589', lock: 'earlier-lock', staging_state: 'staging_failed')
      end

      it 'clears the failure for the object only' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { viewing_direction: 'right-to-left' } }

        expect(failed_content.reload.staging_state).to eq('staging_not_in_progress')
        expect(other_object_failed_content.reload.staging_state).to eq('staging_failed')
        expect(content.reload.staging_state).to eq('staging')
      end
    end

    context 'when saving as draft' do
      it 'stages without accessioning' do
        patch content_path(druid), params: { commit: ContentsController::DRAFT_VALUE,
                                             contents_item: { viewing_direction: 'right-to-left' } }

        expect(response).to redirect_to(object_path(druid))
        expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: false, user:)
      end
    end

    context 'when nothing has changed' do
      it 'stages without updating the object' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { content_type: Cocina::Models::ObjectType.book } }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::Repository).not_to have_received(:update)
        expect(content.reload.lock).to eq(cocina_object.lock)
        expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: true, user:)
      end
    end

    context 'when requesting OCR' do
      it 'saves the OCR settings with the content and stages the object' do
        patch content_path(druid), params: { commit: ContentsController::DRAFT_VALUE,
                                             contents_item: { run_ocr: 'true',
                                                              text_extraction_languages: ['', 'English'] } }

        expect(response).to redirect_to(object_path(druid))
        # The OCR settings are not written to Cocina, so the object is not updated.
        expect(Sdr::Repository).not_to have_received(:update)
        expect(content.reload).to have_attributes(lock: cocina_object.lock, perform_ocr: true,
                                                  ocr_languages: ['English'])
        expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: false, user:)
      end
    end

    context 'when requesting OCR without a language' do
      it 'renders the edit page' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { run_ocr: 'true' } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Sdr::Repository).not_to have_received(:update)
        expect(content.reload.perform_ocr).to be false
        expect(StageFilesJob).not_to have_received(:perform_later)
      end
    end

    context 'when invalid' do
      it 'renders the edit page' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { viewing_direction: 'upside-down' } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Sdr::Repository).not_to have_received(:update)
        expect(StageFilesJob).not_to have_received(:perform_later)
      end
    end

    context 'when the content is invalid for the saved content type' do
      # A dark object's content errors are only warnings.
      let(:cocina_object) do
        build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book)
          .new(access: { view: 'world', download: 'world' })
      end

      before do
        # Published files in a file resource are an error for a book.
        create(:content_file, content_file_set: create(:content_file_set, content:, file_set_type: 'file'),
                              publish: true)
      end

      context 'when depositing' do
        it 'renders the edit page with an error' do
          patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                               contents_item: { content_type: Cocina::Models::ObjectType.book } }

          expect(response).to have_http_status(:unprocessable_content)
          # Marked invalid so that the structure tab is shown (by the sdr-tab-error controller).
          expect(Capybara.string(response.body))
            .to have_css('#structural-pane .is-invalid', text: 'Content errors must be fixed.')
          expect(Sdr::Repository).not_to have_received(:update)
          expect(StageFilesJob).not_to have_received(:perform_later)
        end
      end

      context 'when saving as draft' do
        it 'stages without accessioning' do
          patch content_path(druid), params: { commit: ContentsController::DRAFT_VALUE,
                                               contents_item: { content_type: Cocina::Models::ObjectType.book } }

          expect(response).to redirect_to(object_path(druid))
          expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: false, user:)
        end
      end

      context 'when depositing with a content type for which the content is valid' do
        it 'stages with accessioning' do
          patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                               contents_item: { content_type: Cocina::Models::ObjectType.object } }

          expect(response).to redirect_to(object_path(druid))
          expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: true, user:)
        end
      end
    end

    context 'when saving fails after opening a version' do
      let(:open) { false }

      before do
        allow(Sdr::Repository).to receive(:update).and_raise(Sdr::Repository::Error, 'Updating failed')
      end

      it 'renders the edit page with the content rebased onto the opened version' do
        patch content_path(druid), params: { commit: ContentsController::DRAFT_VALUE,
                                             contents_item: { version_description: 'Added files',
                                                              content_type: Cocina::Models::ObjectType.image } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t('edit.contents.edit.errors.save_failed'))
        expect(Sdr::VersionService).to have_received(:open)
        expect(content.reload.lock).to eq('opened-lock')
        expect(content.reload).to be_staging_not_in_progress
        expect(StageFilesJob).not_to have_received(:perform_later)
      end
    end

    context 'when opening a version fails' do
      let(:open) { false }

      before do
        allow(Sdr::VersionService).to receive(:open).and_raise(Sdr::VersionService::Error, 'Opening version failed')
      end

      it 'renders the edit page without changing the content lock' do
        patch content_path(druid), params: { commit: ContentsController::DRAFT_VALUE,
                                             contents_item: { version_description: 'Added files' } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t('edit.contents.edit.errors.save_failed'))
        expect(content.reload.lock).to eq(cocina_object.lock)
        expect(StageFilesJob).not_to have_received(:perform_later)
      end
    end

    context 'when the version is closed' do
      let(:open) { false }

      it 'opens a new version and stages against it' do
        patch content_path(druid), params: { commit: ContentsController::DRAFT_VALUE,
                                             contents_item: { version_description: 'Added files' } }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::VersionService).to have_received(:open)
          .with(druid:, description: 'Added files', opening_user_name: user.sunetid)
        expect(Sdr::Repository).not_to have_received(:update)
        expect(content.reload.lock).to eq('opened-lock')
        expect(Sdr::VersionService).to have_received(:new).with(druid:).once
        expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: false, user:)
      end
    end

    context 'when the version is closed and the version description is missing' do
      let(:open) { false }

      it 'renders the edit page' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { version_description: '' } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Sdr::VersionService).not_to have_received(:open)
        expect(StageFilesJob).not_to have_received(:perform_later)
      end
    end

    context 'when the version is open and the version description changed' do
      let(:version) { 2 }

      it 'updates the version description' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { version_description: 'Added files' } }

        expect(response).to redirect_to(object_path(druid))
        expect(version_service).to have_received(:update_description)
          .with(description: 'Added files', user_name: user.sunetid)
        expect(Sdr::VersionService).not_to have_received(:open)
        expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: true, user:)
      end
    end

    context 'when the version is not editable' do
      let(:editable) { false }

      it 'redirects to the object page without updating' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { viewing_direction: 'right-to-left' } }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:warning]).to eq(I18n.t('edit.items.edit.warnings.not_editable'))
        expect(Sdr::Repository).not_to have_received(:update)
        expect(StageFilesJob).not_to have_received(:perform_later)
      end
    end

    context 'when the user cannot edit the object' do
      before { Permission.permission_type_edit.destroy_all }

      it 'denies access without updating' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { viewing_direction: 'right-to-left' } }

        expect(response).to redirect_to(root_path)
        expect(Sdr::Repository).not_to have_received(:update)
        expect(StageFilesJob).not_to have_received(:perform_later)
      end
    end

    context 'when the object has changed since the edit page was loaded' do
      let!(:content) { create(:content, :mutable, druid:, lock: 'stale-lock') }

      it 'redirects to the edit page' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { viewing_direction: 'right-to-left' } }

        expect(response).to redirect_to(edit_content_path(druid))
        expect(Sdr::Repository).not_to have_received(:update)
        expect(StageFilesJob).not_to have_received(:perform_later)
        expect(content.reload.lock).to eq('stale-lock')
      end
    end
  end
end
