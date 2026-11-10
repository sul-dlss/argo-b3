# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileDownloadPresenter do
  subject(:presenter) { described_class.new(druid:, druid_token: 'abc123', cocina_version:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_version) { 2 }
  let(:filepath) { 'folder 1/image 1.tif' }
  let(:preserve) { true }
  let(:shelve) { true }
  let(:download) { 'world' }
  let(:content_file) { instance_double(ContentFile, filepath:, preserve:, shelve:, download:) }
  let(:download_path) { '/objects/abc123/file_download?filepath=folder+1%2Fimage+1.tif' }

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

    it 'links to the download endpoint' do
      expect(presenter.link(content_file:)).to eq(download_path)
    end
  end

  context 'when the file is preserved and a later version' do
    it 'links to the download endpoint' do
      expect(presenter.link(content_file:)).to eq(download_path)
    end
  end

  context 'when the file is preserved and the first version is accessioned' do
    let(:cocina_version) { 1 }

    before do
      allow(Sdr::WorkflowService).to receive(:accessioned?).and_return(true)
    end

    it 'links to the download endpoint' do
      expect(presenter.link(content_file:)).to eq(download_path)
      expect(Sdr::WorkflowService).to have_received(:accessioned?).with(druid:)
    end
  end

  context 'when the file is preserved and not shelved, but the first version is not yet accessioned' do
    let(:cocina_version) { 1 }
    let(:shelve) { false }

    it 'returns nil' do
      expect(presenter.link(content_file:)).to be_nil
    end
  end

  context 'when the file is preserved and shelved, but the first version is open' do
    let(:cocina_version) { 1 }

    it 'links to the download endpoint' do
      expect(presenter.link(content_file:)).to eq(download_path)
    end
  end

  context 'when the file is shelved and not preserved' do
    let(:preserve) { false }

    it 'links to the download endpoint' do
      expect(presenter.link(content_file:)).to eq(download_path)
    end
  end

  context 'when the file is shelved and not preserved, but not downloadable' do
    let(:preserve) { false }
    let(:download) { 'none' }

    it 'returns nil' do
      expect(presenter.link(content_file:)).to be_nil
    end
  end

  context 'when the file is neither staged, preserved, nor shelved' do
    let(:preserve) { false }
    let(:shelve) { false }

    it 'returns nil' do
      expect(presenter.link(content_file:)).to be_nil
    end
  end
end
