# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ManageContentTypeJob do
  subject(:job) do
    described_class.new(bulk_action:, druids: [druid],
                        current_resource_type:, new_content_type:,
                        new_resource_type:, viewing_direction:)
  end

  let(:druid) { 'druid:bc123df4567' }
  let(:bulk_action) { create(:bulk_action) }
  let(:log) { StringIO.new }

  let(:current_resource_type) { Cocina::Models::FileSetType.image }
  let(:new_content_type) { Cocina::Models::ObjectType.book }
  let(:new_resource_type) { Cocina::Models::FileSetType.page }
  let(:viewing_direction) { 'left-to-right' }

  let(:cocina_object) do
    build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.image)
      .new(structural: {
             contains: [
               { type: Cocina::Models::FileSetType.image,
                 label: 'Image 1',
                 version: 1,
                 externalIdentifier: 'bc123df4567_1',
                 structural: {} },
               { type: Cocina::Models::FileSetType.file,
                 label: 'File 1',
                 version: 1,
                 externalIdentifier: 'bc123df4567_2',
                 structural: {} }
             ]
           })
  end

  let(:job_item) do
    described_class::JobItem.new(druid:, index: 0, job:).tap do |item|
      allow(item).to receive(:check_update_ability?).and_return(true)
      allow(item).to receive(:open_new_version_if_needed!)
      allow(item).to receive(:close_version_if_needed!)
    end
  end

  before do
    allow(described_class::JobItem).to receive(:new).and_return(job_item)
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(Sdr::Repository).to receive(:update)
  end

  context 'when changing content type and remapping matching resource types' do
    it 'updates the content type and remaps matching resource type file sets' do
      job.perform_now

      expect(job_item).to have_received(:check_update_ability?)
      expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Updated content type')
      expect(Sdr::Repository).to have_received(:update) do |args|
        updated = args[:cocina_object]

        expect(updated.type).to eq(Cocina::Models::ObjectType.book)
        # image file sets should be remapped to page; file file sets unchanged
        expect(updated.structural.contains.map(&:type))
          .to eq([
                   Cocina::Models::FileSetType.page,
                   Cocina::Models::FileSetType.file
                 ])
        # viewing direction for book
        expect(updated.structural.hasMemberOrders.first.viewingDirection).to eq('left-to-right')
        expect(args[:user_name]).to eq(bulk_action.user.sunetid)
        expect(args[:description]).to eq('Updated content type')
      end
      expect(job_item).to have_received(:close_version_if_needed!)

      expect(log.string).to include('Successfully updated content type for')
      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
    end
  end

  context 'when changing content type to image with a viewing direction' do
    let(:new_content_type) { Cocina::Models::ObjectType.image }
    let(:viewing_direction) { 'right-to-left' }

    it 'sets the viewing direction' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:update) do |args|
        updated = args[:cocina_object]

        expect(updated.type).to eq(Cocina::Models::ObjectType.image)
        expect(updated.structural.hasMemberOrders.first.viewingDirection).to eq('right-to-left')
      end
    end
  end

  context 'when only updating the viewing direction on an existing book' do
    let(:new_content_type) { nil }
    let(:current_resource_type) { nil }
    let(:new_resource_type) { nil }
    let(:viewing_direction) { 'right-to-left' }

    let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book) }

    it 'updates the viewing direction without changing the content type' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:update) do |args|
        updated = args[:cocina_object]

        expect(updated.type).to eq(Cocina::Models::ObjectType.book)
        expect(updated.structural.hasMemberOrders.first.viewingDirection).to eq('right-to-left')
      end
    end
  end

  context 'when changing from a book with a reading direction to a type that does not support viewing directions' do
    let(:new_content_type) { Cocina::Models::ObjectType.document }
    let(:current_resource_type) { nil }
    let(:new_resource_type) { nil }
    let(:viewing_direction) { nil }

    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book)
        .new(structural: { hasMemberOrders: [{ viewingDirection: 'left-to-right' }] })
    end

    it 'clears the viewing direction' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:update) do |args|
        updated = args[:cocina_object]

        expect(updated.type).to eq(Cocina::Models::ObjectType.document)
        expect(updated.structural.hasMemberOrders).to be_empty
      end
    end
  end

  context 'when no current resource type is specified (content type change only)' do
    let(:current_resource_type) { nil }
    let(:new_resource_type) { nil }
    let(:viewing_direction) { nil }

    let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.image) }

    it 'changes the content type without modifying structural' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:update) do |args|
        updated = args[:cocina_object]

        expect(updated.type).to eq(Cocina::Models::ObjectType.book)
        expect(updated.structural.hasMemberOrders).to be_empty
      end
    end
  end

  context 'when no current resource type matches any file sets' do
    let(:current_resource_type) { Cocina::Models::FileSetType.audio }

    it 'changes the content type without modifying file set types' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:update) do |args|
        updated = args[:cocina_object]

        expect(updated.type).to eq(Cocina::Models::ObjectType.book)
        # No file sets match audio so none should be remapped
        expect(updated.structural.contains.map(&:type))
          .to eq([
                   Cocina::Models::FileSetType.image,
                   Cocina::Models::FileSetType.file
                 ])
      end
    end
  end

  context 'when the object is a collection' do
    let(:cocina_object) { build(:collection_with_metadata, id: druid) }

    it 'does not update the object and logs an error' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Sdr::Repository).not_to have_received(:update)
      expect(log.string).to include("Object is a #{Cocina::Models::ObjectType.collection} and cannot be updated")

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end

  context 'when no changes are needed' do
    let(:new_content_type) { Cocina::Models::ObjectType.image } # same as current type
    let(:current_resource_type) { Cocina::Models::FileSetType.audio } # no file sets match
    let(:viewing_direction) { nil }

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
end
