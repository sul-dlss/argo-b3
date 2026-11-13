# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StructureFilesJob do
  subject(:job) { described_class.new }

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) do
    build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.image)
      .new(access: { view: 'world', download: 'world' })
  end
  let(:content) { create(:content, :mutable, druid:, lock: cocina_object.lock, structuring_state: 'structuring') }

  before do
    allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
    create(:content_file_binary, content:, filepath: 'image1.tif', mime_type: 'image/tiff')
    create(:content_file_binary, content:, filepath: 'image2.tif', mime_type: 'image/tiff')
  end

  it 'structures the files with the populator for the content type and completes structuring' do
    job.perform(content:, append: false)

    expect(content.content_file_sets.reload.map(&:file_set_type)).to eq(%w[image image])
    expect(content.reload).to be_structured
    expect(Sdr::Repository).to have_received(:find).with(druid:)
  end

  context 'when item details are saved with the content' do
    before do
      content.update!(content_type: Cocina::Models::ObjectType.object, access_view: 'dark', access_download: 'none')
    end

    it 'structures the files with the saved content type and access' do
      job.perform(content:, append: false)

      expect(content.content_file_sets.reload.map(&:file_set_type)).to eq(%w[file file])
      expect(content.content_files.map(&:view)).to eq(%w[dark dark])
    end
  end

  context 'when appending' do
    let!(:existing_content_file_set) do
      create(:content_file_set, content:, position: 1, label: 'Existing').tap do |content_file_set|
        create(:content_file, content_file_set:,
                              content_file_binary: create(:content_file_binary, content:, filepath: 'image0.tif',
                                                                                mime_type: 'image/tiff'))
      end
    end

    it 'adds the unassociated files to the existing resources' do
      job.perform(content:, append: true)

      content_file_sets = content.content_file_sets.reload
      expect(content_file_sets.first).to eq(existing_content_file_set)
      expect(content_file_sets.size).to eq(3)
      expect(content.reload).to be_structured
    end
  end

  context 'when structuring fails' do
    let!(:existing_content_file_set) { create(:content_file_set, content:, label: 'Existing') }

    before do
      # Raised after the existing resources are destroyed, so they are kept only if structuring is rolled back.
      allow(Contents::Populators::Image).to receive(:new).and_raise(StandardError, 'Structuring failed')
      allow(Honeybadger).to receive(:notify)
    end

    it 'notifies and records the failure, leaving the resources unchanged' do
      job.perform(content:, append: false)

      expect(Honeybadger).to have_received(:notify).with(an_instance_of(StandardError), context: { druid: })
      expect(content.reload).to be_structuring_failed
      expect(content.content_file_sets.reload).to contain_exactly(existing_content_file_set)
    end
  end
end
