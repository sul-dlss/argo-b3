# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable-next RSpec/SubjectStub
RSpec.describe BulkActions::BaseJobItem do
  subject(:bulk_action_item) { described_class.new(druid:, index: 2, job:) }

  let(:druid) { 'druid:bb111cc2222' }

  let(:job) { instance_double(BulkActions::DruidsJob, user:, user_id: user.sunetid, close_version?: close_version) }
  let(:user) { instance_double(User, sunetid: 'a_user') }
  let(:close_version) { true }

  describe '.success!' do
    before do
      allow(job).to receive(:success!)
    end

    it 'calls job.success!' do
      bulk_action_item.success!(message: 'Testing successful')
      expect(job).to have_received(:success!).with(druid:, message: 'Success: Testing successful')
    end
  end

  describe '.failure!' do
    before do
      allow(job).to receive(:failure!)
    end

    it 'calls job.failure!' do
      bulk_action_item.failure!(message: 'Testing failed')
      expect(job).to have_received(:failure!).with(druid:, message: 'Error: Testing failed')
    end
  end

  describe '.cocina_object' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO) }

    before do
      allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    end

    it 'returns the cocina object' do
      expect(bulk_action_item.cocina_object).to eq cocina_object
    end
  end

  describe '#save_model_and_deposit!' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid, version: 2, source_id: 'sul:original') }
    let(:opened_cocina_object) { Cocina::Models.with_metadata(build(:dro, id: druid, version: 3), 'lock-v3') }
    let(:version_service) { version_service_double(druid:, open?: false, openable?: true) }

    before do
      allow(job).to receive(:log)
      allow(job).to receive(:success!)
      allow(job).to receive(:failure!)
      allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
      allow(Sdr::Repository).to receive(:source_id_exists?).and_return(false)
      allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object }
      allow(Sdr::VersionService).to receive(:new).with(druid:).and_return(version_service)
      allow(version_service).to receive(:open).and_return(opened_cocina_object)
      allow(Sdr::VersionService).to receive(:closed?).and_return(false)
      allow(Sdr::DepositDraftService).to receive(:call).and_return(nil)
    end

    context 'when the model is changed' do
      it 'opens a version, saves the model to it, deposits, and records success' do
        bulk_action_item.cocina_model.source_id = 'sul:changed'
        bulk_action_item.save_model_and_deposit!(description: 'Updated source ID', success_message: 'Updated')

        expect(version_service).to have_received(:open).with(description: 'Updated source ID',
                                                             opening_user_name: 'a_user')
        expect(Sdr::Repository).to have_received(:update) do |cocina_object:, user_name:, description:|
          expect(cocina_object.identification.sourceId).to eq 'sul:changed'
          expect(cocina_object.lock).to eq 'lock-v3'
          expect(user_name).to eq 'a_user'
          expect(description).to eq 'Updated source ID'
        end
        expect(Sdr::DepositDraftService).to have_received(:call)
        expect(job).to have_received(:success!).with(druid:, message: 'Success: Updated')
      end

      it 'yields after opening the version and before saving' do
        bulk_action_item.cocina_model.source_id = 'sul:changed'
        bulk_action_item.save_model_and_deposit!(description: 'Updated source ID', success_message: 'Updated') do
          expect(version_service).to have_received(:open)
          expect(Sdr::Repository).not_to have_received(:update)
        end

        expect(Sdr::Repository).to have_received(:update)
      end
    end

    context 'when the model is unchanged' do
      it 'records success with the unchanged message without opening a version or saving' do
        bulk_action_item.save_model_and_deposit!(description: 'Updated source ID', success_message: 'Updated',
                                                 unchanged_message: 'No changes to source ID')

        expect(version_service).not_to have_received(:open)
        expect(Sdr::Repository).not_to have_received(:update)
        expect(Sdr::DepositDraftService).not_to have_received(:call)
        expect(job).to have_received(:success!).with(druid:, message: 'Success: No changes to source ID')
      end
    end

    context 'when the model is invalid' do
      it 'records a failure with the joined errors without opening a version or saving' do
        bulk_action_item.cocina_model.source_id = 'invalid'
        bulk_action_item.cocina_model.content_type = 'bogus'
        bulk_action_item.save_model_and_deposit!(description: 'Updated source ID', success_message: 'Updated')

        expect(version_service).not_to have_received(:open)
        expect(Sdr::Repository).not_to have_received(:update)
        expect(job).to have_received(:failure!)
          .with(druid:, message: 'Error: Content type is not included in the list; Source is invalid')
      end
    end
  end

  describe '.open_new_version_if_needed!' do
    let(:version_service) { version_service_double(druid:, open?: open, openable?: openable) }
    let(:open) { false }
    let(:openable) { true }

    before do
      allow(job).to receive(:log)
      allow(Sdr::VersionService).to receive(:new).with(druid:).and_return(version_service)
      allow(version_service).to receive(:open)
    end

    context 'when version is already open' do
      let(:open) { true }

      it 'does not open a new version' do
        bulk_action_item.open_new_version_if_needed!(description: 'Testing open version')
        expect(version_service).not_to have_received(:open)
        expect(job).not_to have_received(:log)
      end
    end

    context 'when version is not open but openable' do
      let(:cocina_object) { build(:dro_with_metadata, id: druid) }
      let(:opened_cocina_object) { Cocina::Models.with_metadata(build(:dro, id: druid, version: 2), 'lock-v2') }

      before do
        allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
        allow(version_service).to receive(:open).and_return(opened_cocina_object)
      end

      it 'opens a new version' do
        bulk_action_item.open_new_version_if_needed!(description: 'Testing open version')
        expect(version_service).to have_received(:open).with(description: 'Testing open version',
                                                             opening_user_name: 'a_user')
        expect(job).to have_received(:log).with('Opened new version (Testing open version)')
        expect(bulk_action_item.cocina_object).to eq opened_cocina_object
      end

      context 'when the cocina model has already been built and changed' do
        it 'refreshes the cocina model with the opened cocina object, retaining changes' do
          bulk_action_item.cocina_model.source_id = 'changed:source-id'
          bulk_action_item.open_new_version_if_needed!(description: 'Testing open version')

          expect(bulk_action_item.cocina_model.previous_cocina_object).to eq opened_cocina_object
          expect(bulk_action_item.cocina_model.source_id).to eq 'changed:source-id'
          expect(bulk_action_item.cocina_model.changed?).to be true
        end
      end
    end

    context 'when version is not openable' do
      let(:openable) { false }

      it 'raises an error' do
        expect do
          bulk_action_item.open_new_version_if_needed!(description: 'Testing open version')
        end.to raise_error('Unable to open new version')
        expect(version_service).not_to have_received(:open)
        expect(job).not_to have_received(:log)
      end
    end
  end

  describe '.deposit_if_needed!' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, version: 2) }
    let(:refound_cocina_object) { instance_double(Cocina::Models::DRO, version: 2) }
    let(:workflow_name) { nil }

    before do
      allow(job).to receive(:log)
      allow(Sdr::Repository).to receive(:find).and_return(cocina_object, refound_cocina_object)
      allow(Sdr::VersionService).to receive(:closed?).and_return(false)
      allow(Sdr::DepositDraftService).to receive(:call).and_return(workflow_name)
    end

    context 'when depositing closes the version' do
      it 'deposits the re-found object in the default lane' do
        bulk_action_item.deposit_if_needed!

        expect(Sdr::Repository).to have_received(:find).with(druid:).twice
        expect(Sdr::DepositDraftService).to have_received(:call)
          .with(cocina_object: refound_cocina_object, user_name: 'a_user', lane_id: 'default')
        expect(job).to have_received(:log).with('Closed version')
      end
    end

    context 'when depositing starts an assembly workflow' do
      let(:workflow_name) { 'assemblyWF' }

      it 'logs the assembly workflow' do
        bulk_action_item.deposit_if_needed!

        expect(job).to have_received(:log).with('Started assemblyWF, which will close the version')
      end
    end

    context 'when the object cannot be deposited' do
      before do
        allow(Sdr::DepositDraftService).to receive(:call)
          .and_raise(Sdr::DepositDraftService::UnsavedChangesError, 'Files have unsaved changes')
      end

      it 'raises a not deposited error' do
        expect { bulk_action_item.deposit_if_needed! }
          .to raise_error(described_class::NotDepositedError, 'Saved, but not deposited: Files have unsaved changes')
      end

      context 'when forced' do
        it 'raises a not deposited error that does not claim a save' do
          expect { bulk_action_item.deposit_if_needed!(force: true) }
            .to raise_error(described_class::NotDepositedError, 'Not deposited: Files have unsaved changes')
        end
      end
    end

    context 'when version is 1' do
      let(:cocina_object) { instance_double(Cocina::Models::DRO, version: 1) }

      it 'does not deposit' do
        bulk_action_item.deposit_if_needed!
        expect(Sdr::DepositDraftService).not_to have_received(:call)
      end

      context 'when forced' do
        it 'deposits' do
          bulk_action_item.deposit_if_needed!(force: true)
          expect(Sdr::DepositDraftService).to have_received(:call)
          expect(job).to have_received(:log).with('Closed version')
        end
      end
    end

    context 'when already closed' do
      before do
        allow(Sdr::VersionService).to receive(:closed?).and_return(true)
      end

      it 'does not deposit' do
        bulk_action_item.deposit_if_needed!
        expect(Sdr::DepositDraftService).not_to have_received(:call)
        expect(job).to have_received(:log).with('Version already closed')
      end
    end

    context 'when user did not request version be closed' do
      let(:close_version) { false }

      it 'does not deposit' do
        bulk_action_item.deposit_if_needed!
        expect(Sdr::VersionService).not_to have_received(:closed?)
        expect(Sdr::DepositDraftService).not_to have_received(:call)
        expect(job).not_to have_received(:log)
      end

      context 'when forced' do
        it 'deposits' do
          bulk_action_item.deposit_if_needed!(force: true)
          expect(Sdr::DepositDraftService).to have_received(:call)
          expect(job).to have_received(:log).with('Closed version')
        end
      end
    end
  end

  describe '.check_update_ability?' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO) }

    before do
      allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
      allow(job).to receive(:failure!)
    end

    context 'when can update' do
      before do
        allow(bulk_action_item).to receive(:allowed_to?).and_return(true)
      end

      it 'returns true' do
        expect(bulk_action_item.check_update_ability?).to be true
        expect(bulk_action_item).to have_received(:allowed_to?)
          .with(:update?, cocina_object, with: ObjectPolicy)
      end
    end

    context 'when cannot update' do
      before do
        allow(bulk_action_item).to receive(:allowed_to?).and_return(false)
      end

      it 'returns false' do
        expect(bulk_action_item.check_update_ability?).to be false
        expect(job).to have_received(:failure!).with(druid:, message: 'Error: Not authorized to update')
      end
    end
  end

  describe '.check_read_ability?' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO) }

    before do
      allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
      allow(job).to receive(:failure!)
    end

    context 'when can read' do
      before do
        allow(bulk_action_item).to receive(:allowed_to?).and_return(true)
      end

      it 'returns true' do
        expect(bulk_action_item.check_read_ability?).to be true
        expect(bulk_action_item).to have_received(:allowed_to?)
          .with(:show?, cocina_object, with: ObjectPolicy)
      end
    end

    context 'when cannot read' do
      before do
        allow(bulk_action_item).to receive(:allowed_to?).and_return(false)
      end

      it 'returns false' do
        expect(bulk_action_item.check_read_ability?).to be false
        expect(job).to have_received(:failure!).with(druid:, message: 'Error: Not authorized to read')
      end
    end
  end
end
