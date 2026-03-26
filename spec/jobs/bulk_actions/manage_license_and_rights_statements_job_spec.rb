# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ManageLicenseAndRightsStatementsJob do
  subject(:job) do
    described_class.new(
      bulk_action:, druids: [druid], close_version: false,
      change_copyright:,
      copyright:,
      change_license:,
      license:,
      change_use_and_reproduction_statement:,
      use_and_reproduction_statement:
    )
  end

  let(:druid) { 'druid:bc123df4567' }
  let(:bulk_action) { create(:bulk_action) }
  let(:log) { StringIO.new }

  let(:change_copyright) { true }
  let(:copyright) { 'Copyright Stanford University' }
  let(:change_license) { true }
  let(:license) { 'https://creativecommons.org/licenses/by/4.0/legalcode' }
  let(:change_use_and_reproduction_statement) { true }
  let(:use_and_reproduction_statement) { 'Please contact rights holder for use.' }

  let(:cocina_object) { build(:dro_with_metadata, id: druid) }

  let(:job_item) do
    described_class::JobItem.new(druid:, index: 0, job:).tap do |item|
      allow(item).to receive(:open_new_version_if_needed!)
      allow(item).to receive(:close_version_if_needed!)
      allow(item).to receive(:check_update_ability?).and_return(true)
    end
  end

  before do
    allow(described_class::JobItem).to receive(:new).and_return(job_item)
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(Sdr::Repository).to receive(:update)
  end

  it 'updates license and rights statements' do
    job.perform_now

    expect(job_item).to have_received(:check_update_ability?)
    expect(job_item)
      .to have_received(:open_new_version_if_needed!)
      .with(description: 'Updated license, copyright statement, and/or use and reproduction statement')

    expect(Sdr::Repository).to have_received(:update) do |args|
      updated_cocina_object = args[:cocina_object]
      expect(updated_cocina_object.access.license).to eq(license)
      expect(updated_cocina_object.access.copyright).to eq(copyright)
      expect(updated_cocina_object.access.useAndReproductionStatement).to eq(use_and_reproduction_statement)
      expect(args[:user_name]).to eq(bulk_action.user.sunetid)
      expect(args[:description]).to eq('Updated license, copyright statement, and/or use and reproduction statement')
    end

    expect(job_item).to have_received(:close_version_if_needed!)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
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

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end

  context 'when no changes are requested' do
    let(:change_copyright) { false }
    let(:change_license) { false }
    let(:change_use_and_reproduction_statement) { false }

    it 'marks the row successful without updating' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)
      expect(log.string).to include('No changes made for')

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
    end
  end

  context 'when the object is not a DRO or collection' do
    let(:cocina_object) { build(:admin_policy_with_metadata, id: druid) }

    it 'fails and does not update' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)
      expect(log.string).to include('Not an item or collection')

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end
end
