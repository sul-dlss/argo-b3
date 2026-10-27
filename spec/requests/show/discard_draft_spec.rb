# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Discard draft' do
  let(:user) { create(:user, :reader) }

  describe 'DELETE /objects/:druid/discard_draft' do
    let(:druid) { 'druid:bc123df4567' }
    let(:cocina_object) { build(:dro_with_metadata, id: druid, version: 2) }

    before do
      create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
      allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
      allow(Sdr::DiscardDraftService).to receive(:call)
      sign_in(user)
    end

    context 'when the draft is discardable' do
      it 'discards the draft and redirects to the object page' do
        delete discard_draft_object_path(druid)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('Draft discarded.')
        expect(Sdr::DiscardDraftService).to have_received(:call).with(cocina_object:)
      end
    end

    context 'when the draft is not discardable' do
      before do
        allow(Sdr::DiscardDraftService).to receive(:call).and_raise(Sdr::DiscardDraftService::NotDiscardableError)
      end

      it 'redirects to the object page with a warning' do
        delete discard_draft_object_path(druid)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:warning]).to eq('This draft cannot be discarded.')
      end
    end

    context 'when the mutable content is busy' do
      before do
        allow(Sdr::DiscardDraftService).to receive(:call).and_raise(Sdr::DiscardDraftService::ContentBusyError)
      end

      it 'redirects to the object page with a warning' do
        delete discard_draft_object_path(druid)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:warning]).to eq('Files for this object are being staged or discovered. ' \
                                      'Try again when that has finished.')
      end
    end

    context 'when discarding fails' do
      before do
        allow(Sdr::DiscardDraftService).to receive(:call).and_raise(Sdr::VersionService::Error, 'Oops')
        allow(Honeybadger).to receive(:notify)
      end

      it 'redirects to the object page with an error and notifies' do
        delete discard_draft_object_path(druid)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:danger]).to eq('Discarding the draft failed.')
        expect(Honeybadger).to have_received(:notify).with(Sdr::VersionService::Error, context: { druid: })
      end
    end

    context 'when the user cannot edit the item' do
      before { Permission.permission_type_edit.destroy_all }

      it 'denies access without discarding' do
        delete discard_draft_object_path(druid)

        expect(response).to redirect_to(root_path)
        expect(Sdr::DiscardDraftService).not_to have_received(:call)
      end
    end
  end
end
