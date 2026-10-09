# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Contents' do
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book) }
  let(:updated_cocina_object) { cocina_object.new(lock: 'updated-lock') }
  let!(:content) { create(:content, druid:, lock: cocina_object.lock, immutable: false) }
  let(:user) { create(:user) }

  before do
    allow(Sdr::Repository).to receive_messages(find: cocina_object, update: updated_cocina_object,
                                               find_solr: build(:solr_item, druid:))
    allow(StageFilesJob).to receive(:perform_later)
    sign_in(user)
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
        expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: true, user:,
                                                                    workflow_context: {})
      end
    end

    context 'when saving as draft' do
      it 'stages without accessioning' do
        patch content_path(druid), params: { commit: ContentsController::DRAFT_VALUE,
                                             contents_item: { viewing_direction: 'right-to-left' } }

        expect(response).to redirect_to(object_path(druid))
        expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: false, user:,
                                                                    workflow_context: {})
      end
    end

    context 'when nothing has changed' do
      it 'stages without updating the object' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { content_type: Cocina::Models::ObjectType.book } }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::Repository).not_to have_received(:update)
        expect(content.reload.lock).to eq(cocina_object.lock)
        expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: true, user:,
                                                                    workflow_context: {})
      end
    end

    context 'when requesting OCR' do
      it 'stages the object' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { run_ocr: 'true',
                                                              text_extraction_languages: ['', 'English'] } }

        expect(response).to redirect_to(object_path(druid))
        # The OCR settings are not written to Cocina, but they do make the form dirty, so the
        # object is updated with an unchanged payload.
        expect(Sdr::Repository).to have_received(:update)
        expect(StageFilesJob).to have_received(:perform_later)
          .with(content:, accession: true, user:,
                workflow_context: { runOcr: true, ocrLanguages: ['English'] })
      end
    end

    context 'when requesting OCR without a language' do
      it 'renders the edit page' do
        patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                             contents_item: { run_ocr: 'true' } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Sdr::Repository).not_to have_received(:update)
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
          expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: false, user:,
                                                                      workflow_context: {})
        end
      end

      context 'when depositing with a content type for which the content is valid' do
        it 'stages with accessioning' do
          patch content_path(druid), params: { commit: ContentsController::DEPOSIT_VALUE,
                                               contents_item: { content_type: Cocina::Models::ObjectType.object } }

          expect(response).to redirect_to(object_path(druid))
          expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: true, user:,
                                                                      workflow_context: {})
        end
      end
    end

    context 'when the object has changed since the edit page was loaded' do
      let!(:content) { create(:content, druid:, lock: 'stale-lock', immutable: false) }

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
