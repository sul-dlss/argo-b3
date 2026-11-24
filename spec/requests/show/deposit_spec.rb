# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deposit' do
  let(:user) { create(:user, :reader) }

  describe 'POST /objects/:druid/deposit' do
    let(:druid) { 'druid:bc123df4567' }
    let(:cocina_object) { build(:dro_with_metadata, id: druid, version: 2) }
    let(:params) { { deposit: { version_description: 'Fixed the title' } } }

    before do
      create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
      allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
      allow(Sdr::DepositDraftService).to receive(:call)
      sign_in(user)
    end

    context 'when the draft is deposited' do
      it 'deposits the draft and redirects to the object page with a toast' do
        post(deposit_object_path(druid), params:)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('Deposit started.')
        expect(Sdr::DepositDraftService).to have_received(:call)
          .with(cocina_object:, user_name: user.sunetid, version_description: 'Fixed the title')
      end

      it 'tracks the deposit for the depositing user' do
        post(deposit_object_path(druid), params:)

        expect(TrackedDeposit.sole).to have_attributes(druid:, version: 2, user:)
      end

      context 'when a Turbo request' do
        it 'shows the toast and refreshes the page with a turbo stream' do
          post deposit_object_path(druid), params:,
                                           headers: { 'Accept' => 'text/vnd.turbo-stream.html, text/html' }

          expect(response.media_type).to eq('text/vnd.turbo-stream.html')
          expect(response.body).to include('Deposit started.')
          expect(response.body).to include('turbo-stream action="refresh"')
        end
      end
    end

    context 'when the mutable content is busy' do
      before do
        allow(Sdr::DepositDraftService).to receive(:call).and_raise(Sdr::DepositDraftService::ContentBusyError)
      end

      it 'redirects to the object page with an error' do
        post(deposit_object_path(druid), params:)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:danger]).to eq('Files for this object are being staged, discovered, or structured. ' \
                                     'Try again when that has finished.')
      end
    end

    context 'when the draft is not depositable' do
      before do
        allow(Sdr::DepositDraftService).to receive(:call).and_raise(Sdr::DepositDraftService::NotDepositableError)
      end

      it 'redirects to the object page with an error, without tracking a deposit' do
        post(deposit_object_path(druid), params:)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:danger]).to eq('This draft cannot be deposited.')
        expect(TrackedDeposit.count).to eq(0)
      end
    end

    context 'when the files have unsaved changes' do
      before do
        allow(Sdr::DepositDraftService).to receive(:call).and_raise(Sdr::DepositDraftService::UnsavedChangesError)
        allow(Sdr::VersionService).to receive(:new).and_return(version_service_double(version: 2))
      end

      it 'redirects to managing files, opening on structure files, with an error' do
        post(deposit_object_path(druid), params:)

        expect(response).to redirect_to("/contents/#{druid}/edit?open_on=structure")
        expect(flash[:danger])
          .to eq('Files have unsaved changes. Save or deposit them from "Edit files and structure".')
      end
    end

    context 'when the content is invalid' do
      before do
        allow(Sdr::DepositDraftService).to receive(:call).and_raise(Sdr::DepositDraftService::InvalidContentError)
      end

      it 'redirects to managing files to show the content errors' do
        post(deposit_object_path(druid), params:)

        expect(response).to redirect_to("/contents/#{druid}/edit?deposit=true")
      end
    end

    context 'when depositing fails' do
      before do
        allow(Sdr::DepositDraftService).to receive(:call).and_raise(Sdr::Repository::Error, 'Oops')
        allow(Honeybadger).to receive(:notify)
      end

      it 'redirects to the object page with an error and notifies' do
        post(deposit_object_path(druid), params:)

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:danger]).to eq('Depositing failed.')
        expect(Honeybadger).to have_received(:notify).with(Sdr::Repository::Error, context: { druid: })
      end
    end

    context 'when the user cannot edit the item' do
      before { Permission.permission_type_edit.destroy_all }

      it 'denies access without depositing' do
        post(deposit_object_path(druid), params:)

        expect(response).to redirect_to(root_path)
        expect(Sdr::DepositDraftService).not_to have_received(:call)
      end
    end
  end
end
