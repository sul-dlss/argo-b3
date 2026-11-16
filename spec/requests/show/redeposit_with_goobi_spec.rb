# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Redeposit with Goobi' do
  let(:user) { create(:user, :reader) }

  describe 'POST /objects/:druid/redeposit_with_goobi' do
    let(:druid) { 'druid:bc123df4567' }
    let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.image, version: 2) }

    before do
      create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
      allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
      allow(Sdr::GoobiRedepositService).to receive(:call)
      sign_in(user)
    end

    context 'when the object can be redeposited with Goobi' do
      it 'starts the Goobi Redeposit and redirects to the object page with a toast' do
        post redeposit_with_goobi_object_path(druid)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('Goobi workflow started.')
        expect(Sdr::GoobiRedepositService).to have_received(:call).with(cocina_object:, user_name: user.sunetid)
      end
    end

    {
      'is not an image or book Item' => [Sdr::GoobiRedepositService::NotGoobiTypeError,
                                         'Only image and book items can be redeposited with Goobi.'],
      'is already being processed by Goobi' => [Sdr::GoobiRedepositService::GoobiProcessingError,
                                                'Goobi is already processing this version. ' \
                                                'Try again after Goobi has deposited it.'],
      'has an active workflow' => [Sdr::GoobiRedepositService::ActiveWorkflowError,
                                   'This object has an active workflow. Try again when it has finished.']
    }.each do |condition, (error_class, message)|
      context "when the object #{condition}" do
        before do
          allow(Sdr::GoobiRedepositService).to receive(:call).and_raise(error_class)
        end

        it 'redirects to the object page with a warning' do
          post redeposit_with_goobi_object_path(druid)

          expect(response).to redirect_to(object_path(druid))
          expect(flash[:warning]).to eq(message)
        end
      end
    end

    context 'when starting the Goobi Redeposit fails' do
      before do
        allow(Sdr::GoobiRedepositService).to receive(:call).and_raise(Sdr::VersionService::Error, 'Oops')
        allow(Honeybadger).to receive(:notify)
      end

      it 'redirects to the object page with an error and notifies' do
        post redeposit_with_goobi_object_path(druid)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:danger]).to eq('The Goobi workflow could not be started. ' \
                                     'Try again, or contact SDR support if the problem continues.')
        expect(Honeybadger).to have_received(:notify).with(Sdr::VersionService::Error, context: { druid: })
      end
    end

    context 'when the user cannot edit the item' do
      before { Permission.permission_type_edit.destroy_all }

      it 'denies access without starting the Goobi Redeposit' do
        post redeposit_with_goobi_object_path(druid)

        expect(response).to redirect_to(root_path)
        expect(Sdr::GoobiRedepositService).not_to have_received(:call)
      end
    end
  end
end
