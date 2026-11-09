# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Content unsaved changes' do
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid).new(lock: 'druid-version-2') }
  let(:content) { create(:content, :mutable, druid:, lock: 'druid-version-2') }
  let!(:uploaded_binary) { create(:content_file_binary, content:, file_location: 'attached') }
  let(:content_token) { Rails.application.message_verifier(:argo).generate(content.id, purpose: 'contents') }

  before do
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    sign_in(create(:user))
  end

  describe 'destroy' do
    it 'discards the unsaved changes and redirects to the object page with a toast' do
      delete content_unsaved_changes_path(content_token)

      expect(response).to redirect_to('/objects/druid:bc123df4567')
      expect(response).to have_http_status(:see_other)
      expect(flash[:toast]).to eq('Unsaved changes to files discarded')
      expect(ContentFileBinary.exists?(uploaded_binary.id)).to be false
      expect(Content.exists?(content.id)).to be true
    end

    context 'when the object has changed since manage files was opened' do
      let(:cocina_object) { build(:dro_with_metadata, id: druid).new(lock: 'druid-version-3') }

      it 'redirects to the object page without discarding' do
        delete content_unsaved_changes_path(content_token)

        expect(response).to redirect_to('/objects/druid:bc123df4567')
        expect(flash[:toast]).to be_nil
        expect(flash[:warning]).to be_nil
        expect(ContentFileBinary.exists?(uploaded_binary.id)).to be true
      end
    end

    context 'when the content is immutable' do
      let(:content) { create(:content, druid:, lock: 'druid-version-2') }

      it 'redirects to the object page without discarding' do
        delete content_unsaved_changes_path(content_token)

        expect(response).to redirect_to('/objects/druid:bc123df4567')
        expect(flash[:toast]).to be_nil
        expect(ContentFileBinary.exists?(uploaded_binary.id)).to be true
      end
    end

    context 'when discovering files' do
      let(:content) { create(:content, :mutable, druid:, lock: 'druid-version-2', mount_state: 'discovering') }

      it 'redirects to the object page with a warning without discarding' do
        delete content_unsaved_changes_path(content_token)

        expect(response).to redirect_to('/objects/druid:bc123df4567')
        expect(flash[:warning]).to eq('Files are being discovered or staged, so unsaved changes to files ' \
                                      'were not discarded.')
        expect(ContentFileBinary.exists?(uploaded_binary.id)).to be true
      end
    end

    context 'when staging' do
      let(:content) { create(:content, :mutable, druid:, lock: 'druid-version-2', staging_state: 'staging') }

      it 'redirects to the object page with a warning without discarding' do
        delete content_unsaved_changes_path(content_token)

        expect(flash[:warning]).to eq('Files are being discovered or staged, so unsaved changes to files ' \
                                      'were not discarded.')
        expect(ContentFileBinary.exists?(uploaded_binary.id)).to be true
      end
    end

    context 'when staging failed' do
      let(:content) { create(:content, :mutable, druid:, lock: 'druid-version-2', staging_state: 'staging_failed') }

      it 'redirects to the object page with a warning without discarding' do
        delete content_unsaved_changes_path(content_token)

        expect(response).to redirect_to('/objects/druid:bc123df4567')
        expect(flash[:warning]).to eq('Staging failed, so unsaved changes to files were not discarded. Retry ' \
                                      'staging, or contact SDR support if the problem continues.')
        expect(ContentFileBinary.exists?(uploaded_binary.id)).to be true
      end
    end
  end
end
