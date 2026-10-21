# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::DepositJob do
  subject(:job) { described_class.new }

  let(:druid) { 'druid:bc123df4567' }
  let(:other_druid) { 'druid:cd234fg5678' }
  let(:apo_druid) { 'druid:hv992ry2431' }
  let(:user) { create(:user) }
  let(:multi_item_deposit_action) do
    create(:multi_item_deposit_action, user:, step: 'deposit', initiating_deposit_state: 'initiating_depositing',
                                       version_description: 'Adding files', perform_ocr: true,
                                       ocr_languages: ['English'])
  end
  # Content locks come from find as ETags, while find_all returns bare locks ('abc123').
  let(:content) { create(:content, :mutable, druid:, lock: 'W/"abc123-gzip"') }
  let(:other_content) { create(:content, :mutable, druid: other_druid, lock: 'W/"abc123-gzip"') }
  let!(:item_deposit_action) do
    create(:item_deposit_action, multi_item_deposit_action:, druid:, deposit_errors: ['Old error'], content:,
                                 content_type: 'book')
  end
  let!(:other_item_deposit_action) do
    create(:item_deposit_action, multi_item_deposit_action:, druid: other_druid, content: other_content,
                                 content_type: 'file')
  end
  let(:effective_groups) { ['workgroup:depositors'] }
  let(:cocina_objects) do
    [druid, other_druid].index_with { |id| build(:dro_with_metadata, id:, admin_policy_id: apo_druid) }
  end
  let(:status) do
    instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: false, openable?: true)
  end
  let(:other_status) do
    instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: true, closeable?: true)
  end
  let(:statuses) { { druid => status, other_druid => other_status } }
  let(:opened_cocina_object) { build(:dro_with_metadata, id: druid).new(lock: 'opened-lock') }

  before do
    create(:permission, :edit, workgroup: 'workgroup:depositors', target_druid: apo_druid)
    allow(Sdr::Repository).to receive(:find_all).and_return(cocina_objects)
    allow(Sdr::VersionService).to receive_messages(statuses:, open: opened_cocina_object)
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
  end

  def perform
    job.perform(multi_item_deposit_action:, effective_groups:)
    multi_item_deposit_action.reload
  end

  shared_examples 'completes with an error' do |error|
    it 'records the error, completes initiating the deposit, and notifies the user' do
      perform

      expect(item_deposit_action.reload.deposit_errors).to eq([error])
      expect(other_item_deposit_action.reload.deposit_errors).to eq([])
      expect(multi_item_deposit_action).to have_attributes(
        step: 'deposit', initiating_deposit_state: 'initiating_deposit_not_in_progress',
        initiating_deposit_completed_at: be_within(1.second).of(Time.current)
      )
      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
        .with('notifications', user, target: 'toast-container', html: include('Deposit check found errors'))
      expect(Sdr::VersionService).not_to have_received(:open)
      expect(StageFilesJob).not_to have_been_enqueued
    end
  end

  context 'when there are no errors' do
    it 'clears previous errors, submits the deposit, completes initiating it, and notifies the user' do
      perform

      expect(item_deposit_action.reload.deposit_errors).to eq([])
      expect(multi_item_deposit_action).to have_attributes(
        step: 'submitted', initiating_deposit_state: 'initiating_deposit_not_in_progress',
        initiating_deposit_completed_at: be_within(1.second).of(Time.current)
      )
      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
        .with('notifications', user, target: 'toast-container', html: include('Deposit started'))
      expect(Sdr::Repository).to have_received(:find_all).with(druids: contain_exactly(druid, other_druid))
      expect(Sdr::VersionService).to have_received(:statuses).with(druids: contain_exactly(druid, other_druid))
    end

    it 'opens a version for a closed object and moves its Content to the new lock' do
      perform

      expect(Sdr::VersionService).to have_received(:open)
        .with(druid:, description: 'Adding files', opening_user_name: user.sunetid)
      expect(content.reload.lock).to eq('opened-lock')
    end

    it 'does not open a version for an open object' do
      perform

      expect(Sdr::VersionService).not_to have_received(:open).with(hash_including(druid: other_druid))
      expect(other_content.reload.lock).to eq('W/"abc123-gzip"')
    end

    it 'sets the OCR settings only for content types that can be OCRed' do
      perform

      expect(content.reload).to have_attributes(perform_ocr: true, ocr_languages: ['English'])
      expect(other_content.reload).to have_attributes(perform_ocr: false, ocr_languages: [])
    end

    it 'starts staging each Content to the assembly location for accessioning' do
      perform

      [content, other_content].each do |staged_content|
        expect(staged_content.reload.staging_state).to eq('staging')
        expect(StageFilesJob).to have_been_enqueued
          .with(content: staged_content, user:, accession: true, notify: false,
                staging_location: Settings.assembly_location)
      end
    end

    context 'when another Content for the object failed staging' do
      let!(:failed_content) { create(:content, :mutable, druid:, lock: 'old-lock', staging_state: 'staging_failed') }

      it 'clears the staging failure' do
        perform

        expect(failed_content.reload.staging_state).to eq('staging_not_in_progress')
      end
    end

    context 'when depositing an Item Deposit fails' do
      let(:error) { Sdr::VersionService::Error.new('Opening version failed') }

      before do
        allow(Sdr::VersionService).to receive(:open).and_raise(error)
        allow(Honeybadger).to receive(:notify)
      end

      it 'records the error on that Item Deposit and deposits the others' do
        perform

        expect(item_deposit_action.reload.deposit_errors)
          .to eq(['An unexpected error occurred while depositing. Contact SDR support for assistance.'])
        expect(content.reload).to have_attributes(lock: 'W/"abc123-gzip"', staging_state: 'staging_not_in_progress')
        expect(Honeybadger).to have_received(:notify).with(error)
        expect(StageFilesJob).to have_been_enqueued.with(content: other_content, user:, accession: true,
                                                         notify: false, staging_location: Settings.assembly_location)
        expect(StageFilesJob).not_to have_been_enqueued.with(hash_including(content:))
        expect(multi_item_deposit_action).to have_attributes(
          step: 'submitted', initiating_deposit_state: 'initiating_deposit_not_in_progress'
        )
      end
    end
  end

  context 'when the object is not found' do
    let(:cocina_objects) { { other_druid => build(:dro_with_metadata, id: other_druid, admin_policy_id: apo_druid) } }

    it_behaves_like 'completes with an error', 'Object not found'
  end

  context 'when the version status is not found' do
    let(:statuses) { { other_druid => other_status } }

    it_behaves_like 'completes with an error', 'Object not found'
  end

  context 'when the user is not authorized to update the object' do
    let(:cocina_objects) do
      { druid => build(:dro_with_metadata, id: druid, admin_policy_id: 'druid:jk987mn6543'),
        other_druid => build(:dro_with_metadata, id: other_druid, admin_policy_id: apo_druid) }
    end

    it_behaves_like 'completes with an error', 'Not authorized to update'
  end

  context 'when the object has changed since discovery' do
    before do
      item_deposit_action.content.update!(lock: 'def456')
    end

    it_behaves_like 'completes with an error', 'Object changed since discovery; re-run Discover files'
  end

  context 'when the Content no longer exists' do
    before do
      item_deposit_action.update!(content: nil)
    end

    it_behaves_like 'completes with an error', 'Object changed since discovery; re-run Discover files'
  end

  context 'when the object is closed and cannot be opened' do
    let(:status) do
      instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: false, openable?: false)
    end

    it_behaves_like 'completes with an error', 'A new version cannot be opened for this object'
  end

  context 'when the object is open and cannot be closed' do
    let(:status) do
      instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: true, closeable?: false)
    end

    it_behaves_like 'completes with an error', 'The open version cannot be closed for this object'
  end

  context 'when checking fails unexpectedly' do
    let(:error) { Sdr::VersionService::Error.new('Retrieving version statuses failed') }

    before do
      allow(Sdr::VersionService).to receive(:statuses).and_raise(error)
      allow(Honeybadger).to receive(:notify)
    end

    it 'records an error on every Item Deposit, notifies Honeybadger, and completes initiating the deposit' do
      perform

      unexpected_error = 'An unexpected error occurred while checking the deposit. Contact SDR support for assistance.'
      expect(item_deposit_action.reload.deposit_errors).to eq([unexpected_error])
      expect(other_item_deposit_action.reload.deposit_errors).to eq([unexpected_error])
      expect(multi_item_deposit_action).to have_attributes(
        step: 'deposit', initiating_deposit_state: 'initiating_deposit_not_in_progress'
      )
      expect(Honeybadger).to have_received(:notify).with(error)
      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
        .with('notifications', user, target: 'toast-container', html: include('Deposit check found errors'))
    end
  end
end
