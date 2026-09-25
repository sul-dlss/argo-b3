# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ManageCollectionsJob do
  subject(:job) { described_class.new(bulk_action:, druids: [druid], close_version: false, collection_druids:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:collection_druids) { ['druid:bk123gh4567'] }
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }

  let(:bulk_action) { create(:bulk_action) }
  let(:log) { StringIO.new }

  let(:job_item) do
    described_class::JobItem.new(druid:, index: 0, job:).tap do |item|
      allow(item).to receive(:check_update_ability?).and_return(true)
      allow(item).to receive(:open_new_version_if_needed!)
      allow(item).to receive(:close_version_if_needed!)
    end
  end

  before do
    allow(described_class::JobItem).to receive(:new).and_return(job_item)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(Sdr::Repository).to receive(:update)
  end

  context 'when adding the object to collections' do
    it 'updates the collections' do
      job.perform_now

      expect(job_item).to have_received(:check_update_ability?)
      expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Updated collection')
      expect(Sdr::Repository).to have_received(:update) do |args|
        expect(args[:cocina_object].structural.isMemberOf).to eq(collection_druids)
        expect(args[:user_name]).to eq(bulk_action.user.sunetid)
        expect(args[:description]).to eq('Updated collection')
      end
      expect(job_item).to have_received(:close_version_if_needed!)

      expect(log.string).to include("#{druid}\tSuccess: Collection updated")
      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
    end
  end

  context 'when removing the object from all collections' do
    let(:collection_druids) { [] }
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid).new(structural: { isMemberOf: ['druid:bk123gh4567'] })
    end

    it 'clears the collections' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:update) do |args|
        expect(args[:cocina_object].structural.isMemberOf).to eq([])
      end
    end
  end

  context 'when the object is a collection' do
    let(:cocina_object) { build(:collection_with_metadata, id: druid) }

    it 'does not update the object and logs an error' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)
      expect(log.string).to include('Not an item')

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end

  context 'when the object is an admin policy' do
    let(:cocina_object) { build(:admin_policy_with_metadata, id: druid) }

    it 'does not update the object and logs an error' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)
      expect(log.string).to include('Not an item')

      expect(bulk_action.reload.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end

  context 'when the user is not authorized to update' do
    before do
      allow(job_item).to receive(:check_update_ability?) do
        job_item.failure!(message: 'Not authorized to update')
        false
      end
    end

    it 'does not update the object' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)

      expect(bulk_action.reload.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end

  context 'when unchanged' do
    let(:collection_druids) { ['druid:bk123gh4567'] }
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid).new(structural: { isMemberOf: collection_druids })
    end

    it 'does not update the object' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)
      expect(log.string).to include('No changes to collections')

      expect(bulk_action.reload.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
    end
  end
end
