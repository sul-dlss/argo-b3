# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileAvailability do
  subject(:file_availability) { described_class.new(druid:, cocina_version:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_version) { 2 }
  let(:filepath) { 'folder 1/image 1.tif' }
  let(:preserve) { true }
  let(:shelve) { true }
  let(:content_file) { instance_double(ContentFile, filepath:, preserve:, shelve:, download: 'world') }

  before do
    allow(Sdr::WorkflowService).to receive(:accessioned?).and_return(false)
  end

  context 'when the file is staged' do
    let(:preserve) { false }
    let(:shelve) { false }
    let(:staged_filepath) { StagingSupport.staging_filepath(druid:, filepath:) }

    before do
      FileUtils.mkdir_p(File.dirname(staged_filepath))
      FileUtils.touch(staged_filepath)
    end

    after { FileUtils.rm_rf(StagingSupport.staging_content_path(druid:)) }

    it 'is available' do
      expect(file_availability.available?(content_file)).to be true
    end
  end

  context 'when the file is preserved and a later version' do
    let(:shelve) { false }

    it 'is available' do
      expect(file_availability.available?(content_file)).to be true
    end
  end

  context 'when the file is preserved and the first version is accessioned' do
    let(:cocina_version) { 1 }
    let(:shelve) { false }

    before do
      allow(Sdr::WorkflowService).to receive(:accessioned?).and_return(true)
    end

    it 'is available' do
      expect(file_availability.available?(content_file)).to be true
      expect(Sdr::WorkflowService).to have_received(:accessioned?).with(druid:)
    end
  end

  context 'when the file is preserved and not shelved, but the first version is not yet accessioned' do
    let(:cocina_version) { 1 }
    let(:shelve) { false }

    it 'is not available' do
      expect(file_availability.available?(content_file)).to be false
    end
  end

  context 'when the file is shelved and not preserved' do
    let(:preserve) { false }

    it 'is available' do
      expect(file_availability.available?(content_file)).to be true
    end
  end

  context 'when the file is shelved and preserved in a first version' do
    let(:cocina_version) { 1 }

    it 'is available without checking whether the version is accessioned' do
      expect(file_availability.available?(content_file)).to be true
      expect(Sdr::WorkflowService).not_to have_received(:accessioned?)
    end
  end

  context 'when the file is shelved with download none' do
    let(:preserve) { false }
    let(:content_file) { instance_double(ContentFile, filepath:, preserve:, shelve:, download: 'none') }

    it 'is available' do
      expect(file_availability.available?(content_file)).to be true
    end
  end

  context 'when the file is neither staged, preserved, nor shelved' do
    let(:preserve) { false }
    let(:shelve) { false }

    it 'is not available' do
      expect(file_availability.available?(content_file)).to be false
    end
  end
end
