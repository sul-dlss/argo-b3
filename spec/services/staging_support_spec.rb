# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StagingSupport do
  let(:druid) { 'druid:bc123df4567' }
  let(:content_path) { described_class.staging_content_path(druid:) }

  after do
    FileUtils.rm_rf(content_path)
  end

  describe '.staging_filepath' do
    it 'returns the filepath within the staging content directory' do
      expect(described_class.staging_filepath(druid:, filepath: 'images/image1.tif'))
        .to eq(File.join(Settings.staging_location, 'bc/123/df/4567/bc123df4567/content/images/image1.tif'))
    end
  end

  describe '.staged_files?' do
    context 'when the staging content directory does not exist' do
      it 'returns false' do
        expect(described_class.staged_files?(druid:)).to be false
      end
    end

    context 'when the staging content directory is empty' do
      before do
        FileUtils.mkdir_p(File.join(content_path, 'images'))
      end

      it 'returns false' do
        expect(described_class.staged_files?(druid:)).to be false
      end
    end

    context 'when the staging content directory contains a file in a subdirectory' do
      before do
        filepath = described_class.staging_filepath(druid:, filepath: 'images/image1.tif')
        FileUtils.mkdir_p(File.dirname(filepath))
        FileUtils.touch(filepath)
      end

      it 'returns true' do
        expect(described_class.staged_files?(druid:)).to be true
      end
    end
  end
end
