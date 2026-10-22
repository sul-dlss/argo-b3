# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDepositAction do
  subject(:multi_item_deposit_action) { create(:multi_item_deposit_action) }

  describe 'defaults' do
    it 'starts on the discovery step with nothing in progress' do
      expect(multi_item_deposit_action).to have_attributes(
        step: 'discovery',
        file_location: 'mount',
        discovery_state: 'discovery_not_in_progress',
        structuring_state: 'structuring_not_in_progress',
        initiating_deposit_state: 'initiating_deposit_not_in_progress',
        publish_preserve_all: false,
        perform_ocr: false,
        ocr_languages: []
      )
    end
  end

  describe 'discovery_state' do
    it 'transitions to discovering and back' do
      multi_item_deposit_action.discovery_started!
      expect(multi_item_deposit_action).to be_discovering

      multi_item_deposit_action.discovery_completed!
      expect(multi_item_deposit_action).to be_discovery_not_in_progress
    end

    it 'records when started and completed' do
      multi_item_deposit_action.update!(discovery_completed_at: 1.day.ago)

      multi_item_deposit_action.discovery_started!
      expect(multi_item_deposit_action.reload).to have_attributes(
        discovery_started_at: be_within(1.second).of(Time.current), discovery_completed_at: nil
      )

      multi_item_deposit_action.discovery_completed!
      expect(multi_item_deposit_action.reload.discovery_completed_at).to be_within(1.second).of(Time.current)
    end

    it 'does not complete when not discovering' do
      expect(multi_item_deposit_action.discovery_completed).to be false
    end
  end

  describe 'structuring_state' do
    it 'transitions to structuring and back' do
      multi_item_deposit_action.structuring_started!
      expect(multi_item_deposit_action).to be_structuring

      multi_item_deposit_action.structuring_completed!
      expect(multi_item_deposit_action).to be_structuring_not_in_progress
    end

    it 'records when started and completed' do
      multi_item_deposit_action.update!(structuring_completed_at: 1.day.ago)

      multi_item_deposit_action.structuring_started!
      expect(multi_item_deposit_action.reload).to have_attributes(
        structuring_started_at: be_within(1.second).of(Time.current), structuring_completed_at: nil
      )

      multi_item_deposit_action.structuring_completed!
      expect(multi_item_deposit_action.reload.structuring_completed_at).to be_within(1.second).of(Time.current)
    end

    it 'does not complete when not structuring' do
      expect(multi_item_deposit_action.structuring_completed).to be false
    end
  end

  describe 'initiating_deposit_state' do
    it 'transitions to initiating_depositing and back' do
      multi_item_deposit_action.initiating_deposit_started!
      expect(multi_item_deposit_action).to be_initiating_depositing

      multi_item_deposit_action.initiating_deposit_completed!
      expect(multi_item_deposit_action).to be_initiating_deposit_not_in_progress
    end

    it 'records when started and completed' do
      multi_item_deposit_action.update!(initiating_deposit_completed_at: 1.day.ago)

      multi_item_deposit_action.initiating_deposit_started!
      expect(multi_item_deposit_action.reload).to have_attributes(
        initiating_deposit_started_at: be_within(1.second).of(Time.current), initiating_deposit_completed_at: nil
      )

      multi_item_deposit_action.initiating_deposit_completed!
      expect(multi_item_deposit_action.reload.initiating_deposit_completed_at).to be_within(1.second).of(Time.current)
    end

    it 'does not complete when not initiating deposit' do
      expect(multi_item_deposit_action.initiating_deposit_completed).to be false
    end
  end

  describe '#structuring_succeeded?' do
    it 'is false before structuring has completed' do
      expect(multi_item_deposit_action).not_to be_structuring_succeeded
    end

    context 'when structuring has completed' do
      before { multi_item_deposit_action.update!(structuring_completed_at: Time.current) }

      it 'is true with only structure warnings' do
        create(:item_deposit_action, multi_item_deposit_action:, content_type_structure_warnings: ['No images'])

        expect(multi_item_deposit_action).to be_structuring_succeeded
      end

      it 'is false with structural CSV errors' do
        create(:item_deposit_action, multi_item_deposit_action:, structural_csv_errors: ['Row 2: Missing filename'])

        expect(multi_item_deposit_action).not_to be_structuring_succeeded
      end

      it 'is false with content type structure errors' do
        create(:item_deposit_action, multi_item_deposit_action:, content_type_structure_errors: ['Too many images'])

        expect(multi_item_deposit_action).not_to be_structuring_succeeded
      end
    end
  end

  describe '#ocr_applicable?' do
    it 'is true when an Item Deposit has a content type that can be OCRed' do
      create(:item_deposit_action, multi_item_deposit_action:, content_type: 'map')
      create(:item_deposit_action, multi_item_deposit_action:, content_type: 'book')

      expect(multi_item_deposit_action).to be_ocr_applicable
    end

    it 'is false when no Item Deposit has a content type that can be OCRed' do
      create(:item_deposit_action, multi_item_deposit_action:, content_type: 'map')
      create(:item_deposit_action, multi_item_deposit_action:, content_type: nil)

      expect(multi_item_deposit_action).not_to be_ocr_applicable
    end
  end

  describe '#structural_metadata_csv_required?' do
    it 'is true when an Item Deposit is media' do
      create(:item_deposit_action, multi_item_deposit_action:, content_type: 'book')
      create(:item_deposit_action, multi_item_deposit_action:, content_type: 'media')

      expect(multi_item_deposit_action).to be_structural_metadata_csv_required
    end

    it 'is false when no Item Deposit is media' do
      create(:item_deposit_action, multi_item_deposit_action:, content_type: 'book')

      expect(multi_item_deposit_action).not_to be_structural_metadata_csv_required
    end
  end

  describe '#all_initial_versions?' do
    it 'is true when every Item Deposit is an initial version' do
      create_list(:item_deposit_action, 2, multi_item_deposit_action:, initial_version: true)

      expect(multi_item_deposit_action).to be_all_initial_versions
    end

    it 'is false when an Item Deposit is not an initial version' do
      create(:item_deposit_action, multi_item_deposit_action:, initial_version: true)
      create(:item_deposit_action, multi_item_deposit_action:, initial_version: false)

      expect(multi_item_deposit_action).not_to be_all_initial_versions
    end

    it 'is false when whether an Item Deposit is an initial version is unknown' do
      create(:item_deposit_action, multi_item_deposit_action:, initial_version: nil)

      expect(multi_item_deposit_action).not_to be_all_initial_versions
    end
  end

  describe '#mount_structural_metadata_csv_path' do
    let(:mount_directory) { Dir.mktmpdir(nil, Rails.root.join('tmp')) }

    before { multi_item_deposit_action.mount_path = mount_directory }

    after { FileUtils.rm_rf(mount_directory) }

    it 'returns the path when the CSV is at the root of the mount path' do
      File.write(File.join(mount_directory, 'structural_metadata.csv'), 'druid')

      expect(multi_item_deposit_action.mount_structural_metadata_csv_path)
        .to eq(File.join(mount_directory, 'structural_metadata.csv'))
    end

    it 'returns nil when the CSV is not found' do
      expect(multi_item_deposit_action.mount_structural_metadata_csv_path).to be_nil
    end

    it 'returns nil without a mount path' do
      multi_item_deposit_action.mount_path = nil

      expect(multi_item_deposit_action.mount_structural_metadata_csv_path).to be_nil
    end
  end

  describe '#name' do
    it 'returns the name with the description' do
      expect(described_class.new(id: 5, description: 'Maps').name).to eq('Multi-item deposit 5: Maps')
    end

    context 'when there is no description' do
      it 'returns the name without the description' do
        expect(described_class.new(id: 5, description: '').name).to eq('Multi-item deposit 5')
      end
    end
  end

  describe '#destroy' do
    let(:content) { create(:content, :mutable) }

    before do
      create(:item_deposit_action, multi_item_deposit_action:, content:)
    end

    it 'destroys the item deposit actions but not their contents' do
      expect { multi_item_deposit_action.destroy! }.to change(ItemDepositAction, :count).by(-1)
      expect(Content.exists?(content.id)).to be true
    end
  end
end
