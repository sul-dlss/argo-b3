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
    allow(Sdr::PurgeService).to receive(:purgeable?).and_return(true)
    create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
    sign_in(user)
  end

  describe 'show' do
    let(:content_token) { Rails.application.message_verifier(:argo).generate(content.id, purpose: 'contents') }

    it 'does not mark the actions as busy' do
      get content_path(content_token)

      expect(response.body).not_to include('data-disable-actions-target="busy"')
    end

    it 'shows the number of files in the heading' do
      get content_path(content_token)

      expect(Capybara.string(response.body)).to have_css('h2', exact_text: 'Files (0)')
    end

    context 'when the content has files' do
      before do
        create(:content_file_binary, content:, filepath: 'image1.tif')
        create(:content_file_binary, content:, filepath: 'image2.tif')
      end

      it 'shows the number of files in the heading' do
        get content_path(content_token)

        expect(Capybara.string(response.body)).to have_css('h2', exact_text: 'Files (2)')
      end
    end

    context 'when discovering files' do
      let!(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock, mount_state: 'discovering') }

      it 'marks the actions as busy' do
        get content_path(content_token)

        expect(response.body).to include('data-disable-actions-target="busy"')
      end
    end

    context 'when staging' do
      let!(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock, staging_state: 'staging') }

      it 'marks the actions as busy' do
        get content_path(content_token)

        expect(response.body).to include('data-disable-actions-target="busy"')
      end
    end
  end

  describe 'edit' do
    context 'when the version is not editable' do
      let(:editable) { false }

      it 'redirects to the object page' do
        get edit_content_path(druid)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:danger]).to eq(I18n.t('edit.items.edit.warnings.not_editable'))
      end
    end

    context 'when depositing stopped with a process in error' do
      let(:version_service) { version_service_double(editable?: false, assembly_stopped_with_error?: true, version:) }

      it 'renders without text extraction settings or a deposit button' do
        get edit_content_path(druid)

        expect(response).to have_http_status(:ok)
        page = Capybara.string(response.body)
        expect(page).to have_no_field('contents_item[perform_ocr]', type: 'radio')
        expect(page).to have_no_field('contents_item[perform_speech_to_text]', type: 'radio')
        expect(page).to have_no_button('Deposit', type: 'submit')
      end
    end

    context 'when the content is staging' do
      # Staging moves the content to the saved object's lock, so it may no longer match the fetched object.
      let!(:content) { create(:content, :mutable, druid:, lock: 'saved-lock', staging_state: 'staging') }

      it 'redirects to the object page' do
        get edit_content_path(druid)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:danger]).to eq(I18n.t('edit.contents.edit.warnings.staging'))
        expect(Content.where(druid:)).to contain_exactly(content)
      end
    end

    it 'sets the page title with the object title' do
      allow(Sdr::Repository).to receive(:find_solr).and_return(build(:solr_item, druid:, title: 'Maps & charts'))

      get edit_content_path(druid)

      expect(Capybara.string(response.body))
        .to have_title('Manage files and structure – Maps & charts | Argo B3', exact: true)
    end

    context 'when the initial version' do
      before { content.update!(step: 'deposit') }

      it 'does not render the version description' do
        get edit_content_path(druid)

        expect(response).to have_http_status(:ok)
        expect(Capybara.string(response.body)).to have_no_field('Version description')
      end
    end

    context 'when an item' do
      it 'renders the item details step' do
        get edit_content_path(druid)

        page = Capybara.string(response.body)
        expect(page).to have_css('ol[aria-label="Manage files progress"] li', count: 4)
        expect(page).to have_css('li[aria-current="step"]', text: 'Item details')
        expect(page).to have_select('Content type', visible: :all)
        expect(page).to have_no_css('#file-dropzone', visible: :all)
      end

      it 'selects the embargo toggle from the object' do
        get edit_content_path(druid)

        page = Capybara.string(response.body)
        expect(page).to have_checked_field('Without embargo', visible: :all)
      end

      it 'renders the file location choices in order' do
        content.update!(step: 'files')
        get edit_content_path(druid)

        page = Capybara.string(response.body)
        labels = page.all('input[type="radio"][name$="[file_location_choice]"]', visible: :all)
                     .map { |radio| page.find("label[for='#{radio[:id]}']", visible: :all).text.strip }
        expect(labels).to eq(['Select files from computer', 'Globus', 'Select files from mount'])
      end

      it 'hides the dropzone icon from screen readers' do
        content.update!(step: 'files')
        get edit_content_path(druid)

        page = Capybara.string(response.body)
        expect(page).to have_css('#file-dropzone .dz-message i.bi-cloud-arrow-up-fill[aria-hidden="true"]',
                                 visible: :all)
      end

      it 'renders the navigation, save as draft, and purge buttons on the first step' do
        get edit_content_path(druid)

        page = Capybara.string(response.body)
        expect(page).to have_css('a[href^="/contents/"][href$="/unsaved_changes"][data-turbo-method="delete"]',
                                 text: 'Cancel', count: 1)
        expect(page).to have_no_button('Previous')
        expect(page).to have_css('button[type="submit"][form="item_form"][value="next"]', text: 'Next')
        expect(page).to have_css('button[type="submit"][form="item_form"][value="draft"]', text: 'Save as draft')
        expect(page).to have_no_button('Deposit')
        expect(page).to have_link('Purge item', href: "/objects/#{druid}/purge", count: 1)
        expect(page).to have_no_link('Discard draft')
        expect(Sdr::PurgeService).to have_received(:purgeable?).with(druid:, version: 1).once
      end

      it 'renders a Next that requires files on the add and edit files step' do
        content.update!(step: 'files')
        get edit_content_path(druid)

        page = Capybara.string(response.body)
        expect(page).to have_css('li[aria-current="step"]', text: 'Add and edit files')
        expect(page).to have_button('Previous')
        expect(page).to have_css('button[value="next"][data-files-required-target="submit"]', text: 'Next')
        expect(page).to have_css('[data-files-required-target="reason"]', text: 'Add at least one file to continue.')
      end

      it 'renders the deposit button on the last step' do
        content.update!(step: 'deposit')
        get edit_content_path(druid)

        page = Capybara.string(response.body)
        expect(page).to have_button('Previous')
        expect(page).to have_no_button('Next')
        expect(page).to have_css('button[type="submit"][form="item_form"][value="deposit"]', text: 'Deposit')
      end
    end

    context 'when item details were saved with the content' do
      before { content.update!(content_type: Cocina::Models::ObjectType.image, access_view: 'world') }

      it 'prefills them' do
        get edit_content_path(druid)

        expect(Capybara.string(response.body)).to have_select('Content type', selected: 'image', visible: :all)
      end
    end

    context 'when structuring files' do
      let!(:content) do
        create(:content, :mutable, druid:, lock: cocina_object.lock, step: 'structure',
                                   structuring_state: 'structuring')
      end

      it 'renders the wait page, which refreshes' do
        get edit_content_path(druid)

        page = Capybara.string(response.body)
        expect(page).to have_css('[data-controller="scheduled-refresh"]')
        expect(page).to have_css('[role="status"]', text: 'Structuring files...')
        expect(page).to have_css('li[aria-current="step"]', text: 'Structure files')
        expect(page).to have_no_button('Next')
      end
    end

    context 'when discovering files' do
      let!(:content) do
        create(:content, :mutable, druid:, lock: cocina_object.lock, step: 'files', mount_state: 'discovering')
      end

      it 'renders the wait page' do
        get edit_content_path(druid)

        expect(Capybara.string(response.body)).to have_css('[role="status"]', text: 'Discovering files...')
      end
    end

    context 'when files were just structured' do
      let!(:content) do
        create(:content, :mutable, druid:, lock: cocina_object.lock, step: 'structure', structuring_state: 'structured')
      end

      before do
        create(:content_file, content_file_set: create(:content_file_set, content:, file_set_type: 'page'),
                              content_file_binary: create(:content_file_binary, content:, mime_type: 'image/jpeg'))
      end

      it 'renders the model used once' do
        get edit_content_path(druid)

        expect(Capybara.string(response.body))
          .to have_css('.alert-info', text: 'Files were structured with the Book (resource per page) model.')
        expect(content.reload).to be_structuring_not_in_progress

        get edit_content_path(druid)

        expect(Capybara.string(response.body)).to have_no_css('.alert-info')
      end
    end

    context 'when structuring failed' do
      let!(:content) do
        create(:content, :mutable, druid:, lock: cocina_object.lock, step: 'structure',
                                   structuring_state: 'structuring_failed')
      end

      it 'renders the failure' do
        get edit_content_path(druid)

        expect(Capybara.string(response.body)).to have_css('.alert-danger', text: 'Structuring files failed.')
      end
    end

    context 'when an agreement' do
      let(:cocina_object) { build(:agreement_with_metadata, id: druid) }

      before do
        allow(Sdr::Repository).to receive(:find_solr).and_return(build(:solr_item, :agreement, druid:))
      end

      it 'opens on the add and edit files step, without an item details step' do
        get edit_content_path(druid)

        page = Capybara.string(response.body)
        expect(page).to have_css('ol[aria-label="Manage files progress"] li', count: 3)
        expect(page).to have_css('li[aria-current="step"]', text: 'Add and edit files')
        expect(page).to have_no_text('Item details')
        expect(page).to have_no_select('Content type', visible: :all)
        expect(page).to have_no_button('Previous')
        expect(page).to have_button('Next')
      end
    end

    context 'when the version is open' do
      let(:version) { 2 }

      before { content.update!(step: 'deposit') }

      it 'prefills the version description from the open version' do
        get edit_content_path(druid)

        expect(Capybara.string(response.body)).to have_field('Version description', with: 'Initial version')
        expect(Sdr::VersionService).to have_received(:new).with(druid:).once
      end
    end

    context 'when the open version is not the first version' do
      let(:cocina_object) { build(:dro_with_metadata, id: druid, version: 2) }
      let(:version_service) { version_service_double(open?: true, editable?: true, version: 2, discardable?: true) }

      # A later version is not purgeable without checking SDR.
      before { allow(Sdr::PurgeService).to receive(:purgeable?).and_call_original }

      it 'renders the discard draft button' do
        get edit_content_path(druid)

        page = Capybara.string(response.body)
        expect(page).to have_link('Discard draft', href: "/objects/#{druid}/discard_draft", count: 1)
        expect(page).to have_no_link('Purge')
      end
    end

    context 'when the version is closed' do
      let(:open) { false }

      before { content.update!(step: 'deposit') }

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

    context 'when the content is invalid for the content type' do
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

      it 'renders the content error on the structure step when depositing from elsewhere found it' do
        get edit_content_path(druid, deposit: true)

        expect(response).to have_http_status(:ok)
        page = Capybara.string(response.body)
        expect(page).to have_css('li[aria-current="step"]', text: 'Structure files')
        expect(page).to have_css('.invalid-feedback', text: 'Content errors must be fixed.')
        expect(content.reload.step).to eq('structure')
      end

      it 'does not render the content error otherwise' do
        get edit_content_path(druid)

        expect(Capybara.string(response.body)).to have_no_text('Content errors must be fixed.')
      end
    end

    context 'when the user cannot edit the object' do
      before { Permission.permission_type_edit.destroy_all }

      it 'denies access' do
        get edit_content_path(druid)

        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq(I18n.t('errors.not_authorized'))
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

    context 'when adding an embargo' do
      it 'updates the access of the object' do
        patch content_path(druid), params: { commit: ContentsController::DRAFT_VALUE,
                                             contents_item: { with_embargo: true, embargo_release_date: '2030-01-01',
                                                              access_view: 'dark', access_download: 'none',
                                                              embargo_view: 'world', embargo_download: 'world' } }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::Repository).to have_received(:update)
          .with(cocina_object: having_attributes(
            access: having_attributes(view: 'dark', download: 'none',
                                      embargo: having_attributes(view: 'world', download: 'world'))
          ), user_name: user.sunetid, description: nil)
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

    context 'when the content is staging' do
      let!(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock, staging_state: 'staging') }

      it 'redirects to the object page without saving' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { viewing_direction: 'right-to-left' } }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:danger]).to eq(I18n.t('edit.contents.edit.warnings.staging'))
        expect(Sdr::Repository).not_to have_received(:update)
        expect(StageFilesJob).not_to have_received(:perform_later)
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
                                             contents_item: { perform_ocr: 'true',
                                                              ocr_languages: ['', 'English'] } }

        expect(response).to redirect_to(object_path(druid))
        # The OCR settings are not written to Cocina, so the object is not updated.
        expect(Sdr::Repository).not_to have_received(:update)
        expect(content.reload).to have_attributes(lock: cocina_object.lock, perform_ocr: true,
                                                  ocr_languages: ['English'])
        expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: false, user:)
      end
    end

    context 'when requesting speech to text for media' do
      let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.media) }

      it 'saves the speech to text setting with the content and stages the object' do
        patch content_path(druid), params: { commit: ContentsController::DRAFT_VALUE,
                                             contents_item: { perform_speech_to_text: 'true' } }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::Repository).not_to have_received(:update)
        expect(content.reload).to have_attributes(lock: cocina_object.lock, perform_speech_to_text: true)
        expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: false, user:)
      end
    end

    context 'when requesting OCR without a language' do
      it 'renders the edit page' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { perform_ocr: 'true' } }

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
          page = Capybara.string(response.body)
          expect(page).to have_css('li[aria-current="step"]', text: 'Structure files')
          expect(page).to have_css('.invalid-feedback', text: 'Content errors must be fixed.')
          expect(content.reload.step).to eq('structure')
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

    context 'when depositing stopped with a process in error' do
      let(:version_service) { version_service_double(editable?: false, assembly_stopped_with_error?: true, version:) }

      before { content.update!(perform_ocr: true, ocr_languages: ['English']) }

      it 'stages the draft, keeping the saved text extraction settings' do
        # The disabled text extraction fields are not submitted.
        patch content_path(druid), params: { commit: ContentsController::DRAFT_VALUE,
                                             contents_item: { viewing_direction: 'right-to-left' } }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::Repository).to have_received(:update)
        expect(content.reload).to have_attributes(perform_ocr: true, ocr_languages: ['English'])
        expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: false, user:)
      end

      context 'when depositing' do
        it 'redirects to the object page with a warning without updating' do
          patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                               contents_item: { viewing_direction: 'right-to-left' } }

          expect(response).to redirect_to(object_path(druid))
          expect(flash[:warning]).to eq("This item can't be deposited until the process in error is retried.")
          expect(Sdr::Repository).not_to have_received(:update)
          expect(StageFilesJob).not_to have_received(:perform_later)
        end
      end
    end

    context 'when the version is not editable' do
      let(:editable) { false }

      it 'redirects to the object page without updating' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { viewing_direction: 'right-to-left' } }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:danger]).to eq(I18n.t('edit.items.edit.warnings.not_editable'))
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

  describe 'the structure step' do
    let!(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock, step: 'structure') }

    before do
      create(:content_file, content_file_set: create(:content_file_set, content:),
                            content_file_binary: create(:content_file_binary, content:, mime_type: 'image/tiff'))
    end

    it 'renders the strategy, the validation frame, the restructure button, the CSV upload, and delete all' do
      get edit_content_path(druid)

      page = response.parsed_body
      expect(page.text).to include('Strategy for structuring: Book (resource per page)')
      frame = page.at_css("turbo-frame#structure-validation_content_#{content.id}")
      # The selected content type and access are read from the content, so they are not params.
      expect(frame['src']).to match(%r{\A/contents/[^/?]+/structure/validation\z})
      restructure_form = page.css(%(form[action="/contents/#{druid}"]))
                             .find { |form| form.at_css('input[name="commit"][value="restructure"]') }
      expect(restructure_form.at_css('button').text.strip).to eq('Clear and structure files again')
      checkbox = page.at_css('input[type="checkbox"][name="structural_csv[allow_file_deletion]"]')
      expect(checkbox['checked']).to be_nil
      delete_form = page.css('form[action$="/structure"]')
                        .find { |form| form.at_css('input[name="_method"][value="delete"]') }
      expect(delete_form['data-turbo-confirm']).to eq('Are you sure you want to delete all files and resources?')
      expect(page.text).not_to include('Append files to structure')
    end

    context 'when item details were saved with the content' do
      before { content.update!(content_type: Cocina::Models::ObjectType.image) }

      it 'renders the strategy for the saved content type' do
        get edit_content_path(druid)

        expect(response.body).to include('Strategy for structuring: Image (resource per image)')
      end
    end
  end

  describe 'moving between steps' do
    before { allow(StructureFilesJob).to receive(:perform_later) }

    context 'when leaving the item details step' do
      it 'saves the item details with the content and moves to the next step without saving the object' do
        patch content_path(druid), params: { commit: ContentsController::NEXT_VALUE,
                                             contents_item: { content_type: Cocina::Models::ObjectType.image,
                                                              perform_ocr: 'true', ocr_languages: ['', 'English'],
                                                              with_embargo: 'false', access_view: 'dark',
                                                              access_download: 'none' } }

        expect(response).to redirect_to(edit_content_path(druid))
        expect(content.reload).to have_attributes(step: 'files', content_type: Cocina::Models::ObjectType.image,
                                                  perform_ocr: true, ocr_languages: ['English'],
                                                  access_view: 'dark', access_download: 'none')
        expect(Sdr::Repository).not_to have_received(:update)
        expect(StageFilesJob).not_to have_received(:perform_later)
      end

      context 'when the item details are invalid' do
        it 'renders the item details step with the error' do
          patch content_path(druid), params: { commit: ContentsController::NEXT_VALUE,
                                               contents_item: { perform_ocr: 'true' } }

          expect(response).to have_http_status(:unprocessable_content)
          expect(Capybara.string(response.body)).to have_css('li[aria-current="step"]', text: 'Item details')
          expect(content.reload).to have_attributes(step: 'details', content_type: nil)
        end
      end
    end

    context 'when leaving the add and edit files step without resources' do
      before do
        content.update!(step: 'files')
        create(:content_file_binary, content:)
      end

      it 'structures the files' do
        patch content_path(druid), params: { commit: ContentsController::NEXT_VALUE }

        expect(response).to redirect_to(edit_content_path(druid))
        expect(content.reload).to have_attributes(step: 'structure', structuring_state: 'structuring')
        expect(StructureFilesJob).to have_received(:perform_later).with(content:, append: false)
      end
    end

    context 'when leaving the add and edit files step without files' do
      before { content.update!(step: 'files') }

      it 'renders the add and edit files step without structuring' do
        patch content_path(druid), params: { commit: ContentsController::NEXT_VALUE }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Capybara.string(response.body)).to have_css('li[aria-current="step"]', text: 'Add and edit files')
        expect(content.reload).to have_attributes(step: 'files', structuring_state: 'structuring_not_in_progress')
        expect(StructureFilesJob).not_to have_received(:perform_later)
      end
    end

    context 'when leaving the add and edit files step with resources and unassociated files' do
      before do
        content.update!(step: 'files')
        create(:content_file, content_file_set: create(:content_file_set, content:))
        create(:content_file_binary, content:, filepath: 'new.tif')
      end

      it 'appends the files' do
        patch content_path(druid), params: { commit: ContentsController::NEXT_VALUE }

        expect(content.reload).to have_attributes(step: 'structure', structuring_state: 'structuring')
        expect(StructureFilesJob).to have_received(:perform_later).with(content:, append: true)
      end
    end

    context 'when leaving the add and edit files step with every file in a resource' do
      before do
        content.update!(step: 'files')
        create(:content_file, content_file_set: create(:content_file_set, content:))
      end

      it 'moves to the structure step without structuring' do
        patch content_path(druid), params: { commit: ContentsController::NEXT_VALUE }

        expect(content.reload).to have_attributes(step: 'structure', structuring_state: 'structuring_not_in_progress')
        expect(StructureFilesJob).not_to have_received(:perform_later)
      end
    end

    context 'when returning from the deposit step' do
      let(:version) { 2 }

      before { content.update!(step: 'deposit', content_type: Cocina::Models::ObjectType.image) }

      it 'saves the version description and keeps the saved item details' do
        patch content_path(druid), params: { commit: ContentsController::PREVIOUS_VALUE,
                                             contents_item: { version_description: 'Added pages' } }

        expect(response).to redirect_to(edit_content_path(druid))
        expect(content.reload).to have_attributes(step: 'structure', version_description: 'Added pages',
                                                  content_type: Cocina::Models::ObjectType.image)
      end
    end

    context 'when structuring again' do
      before { content.update!(step: 'structure') }

      it 'structures the files' do
        patch content_path(druid), params: { commit: ContentsController::RESTRUCTURE_VALUE }

        expect(response).to redirect_to(edit_content_path(druid))
        expect(StructureFilesJob).to have_received(:perform_later).with(content:, append: false)
      end
    end

    context 'when the content is busy' do
      let!(:content) do
        create(:content, :mutable, druid:, lock: cocina_object.lock, step: 'structure',
                                   structuring_state: 'structuring')
      end

      it 'redirects to the edit page without changing anything' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE }

        expect(response).to redirect_to(edit_content_path(druid))
        expect(StructureFilesJob).not_to have_received(:perform_later)
        expect(StageFilesJob).not_to have_received(:perform_later)
      end
    end

    context 'when saving as draft with saved item details' do
      before do
        patch content_path(druid), params: { commit: ContentsController::NEXT_VALUE,
                                             contents_item: { viewing_direction: 'right-to-left' } }
      end

      it 'saves them to the object and starts again from the first step' do
        patch content_path(druid), params: { commit: ContentsController::DRAFT_VALUE }

        expect(Sdr::Repository).to have_received(:update)
          .with(cocina_object: having_attributes(
            structural: having_attributes(hasMemberOrders: [having_attributes(viewingDirection: 'right-to-left')])
          ), user_name: user.sunetid, description: nil)
        expect(content.reload).to have_attributes(step: 'details', viewing_direction: nil)
      end
    end

    context 'when depositing with invalid item details' do
      before { content.update!(step: 'deposit') }

      it 'renders the item details step' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { viewing_direction: 'upside-down' } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Capybara.string(response.body)).to have_css('li[aria-current="step"]', text: 'Item details')
        expect(content.reload.step).to eq('details')
      end
    end
  end

  describe 'uploading a structural CSV' do
    let(:content_file_set) { create(:content_file_set, content:, label: 'Page 1', file_set_type: 'page') }
    let(:content_file_binary) do
      create(:content_file_binary, content:, filepath: 'page_0001.tif', mime_type: 'image/tiff')
    end
    let(:csv_string) { StructuralCsv::Export.as_csv(content:).sub('Page 1', 'New label') }
    let(:csv_file) do
      Rack::Test::UploadedFile.new(StringIO.new(csv_string), 'text/csv', original_filename: 'structure.csv')
    end

    before do
      content.update!(step: 'structure')
      create(:content_file, content_file_set:, content_file_binary:)
    end

    def upload(params = { structural_csv: { csv_file: } })
      patch content_path(druid), params: { commit: ContentsController::CSV_VALUE, **params }
    end

    def allow_file_deletion_checkbox
      response.parsed_body.at_css('input[type="checkbox"][name="structural_csv[allow_file_deletion]"]')
    end

    it 'updates the structure and returns to the structure step with a toast' do
      upload

      expect(response).to redirect_to(edit_content_path(druid))
      expect(flash[:toast]).to eq('Structure updated from CSV')
      expect(content.content_file_sets.reload.sole.label).to eq('New label')
      expect(content.reload.step).to eq('structure')
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
