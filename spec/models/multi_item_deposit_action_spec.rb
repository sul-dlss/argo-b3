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

  describe '#destroy' do
    let(:content) { create(:content, immutable: false) }

    before do
      create(:item_deposit_action, multi_item_deposit_action:, content:)
    end

    it 'destroys the item deposit actions but not their contents' do
      expect { multi_item_deposit_action.destroy! }.to change(ItemDepositAction, :count).by(-1)
      expect(Content.exists?(content.id)).to be true
    end
  end
end
