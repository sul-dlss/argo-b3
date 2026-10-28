# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Purge object' do
  let(:user) { create(:user, :reader) }

  describe 'DELETE /objects/:druid/purge' do
    let(:druid) { 'druid:bc123df4567' }
    let(:cocina_object) { build(:dro_with_metadata, id: druid) }

    before do
      create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
      allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
      allow(Sdr::PurgeService).to receive(:purge)
      sign_in(user)
    end

    context 'when the object can be purged' do
      it 'purges the object and redirects to the home page' do
        delete purge_object_path(druid)

        expect(response).to redirect_to(root_path)
        expect(flash[:toast]).to eq('Object purged.')
        expect(Sdr::PurgeService).to have_received(:purge).with(druid:, user_name: user.sunetid)
      end
    end

    context 'when the object cannot be purged' do
      before do
        allow(Sdr::PurgeService).to receive(:purge).and_raise(Sdr::PurgeService::CannotPurgeError)
      end

      it 'redirects to the object page with a warning' do
        delete purge_object_path(druid)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:warning]).to eq('This object cannot be purged because it has been submitted.')
      end
    end

    context 'when the content is busy' do
      before do
        allow(Sdr::PurgeService).to receive(:purge).and_raise(Sdr::PurgeService::ContentBusyError)
      end

      it 'redirects to the object page with a warning' do
        delete purge_object_path(druid)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:warning]).to eq('Files for this object are being staged or discovered. ' \
                                      'Try again when that has finished.')
      end
    end

    context 'when purging fails' do
      before do
        allow(Sdr::PurgeService).to receive(:purge).and_raise(Sdr::PurgeService::Error, 'Oops')
        allow(Honeybadger).to receive(:notify)
      end

      it 'redirects to the object page with an error and notifies' do
        delete purge_object_path(druid)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:danger]).to eq('Purging failed.')
        expect(Honeybadger).to have_received(:notify).with(Sdr::PurgeService::Error, context: { druid: })
      end
    end

    context 'when the user cannot edit the object' do
      before { Permission.permission_type_edit.destroy_all }

      it 'denies access without purging' do
        delete purge_object_path(druid)

        expect(response).to redirect_to(root_path)
        expect(Sdr::PurgeService).not_to have_received(:purge)
      end
    end
  end
end
