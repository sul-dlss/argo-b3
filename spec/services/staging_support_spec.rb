# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StagingSupport do
  let(:druid) { 'druid:bc123df4567' }

  after do
    described_class.locations.each do |staging_location|
      FileUtils.rm_rf(described_class.staging_content_path(druid:, staging_location:))
    end
  end

  def stage_file(staging_location:)
    filepath = described_class.staging_filepath(druid:, filepath: 'images/image1.tif', staging_location:)
    FileUtils.mkdir_p(File.dirname(filepath))
    FileUtils.touch(filepath)
  end

  describe '.staging_filepath' do
    it 'returns the filepath within the staging content directory' do
      expect(described_class.staging_filepath(druid:, filepath: 'images/image1.tif'))
        .to eq(File.join(Settings.staging_location, 'bc/123/df/4567/bc123df4567/content/images/image1.tif'))
    end

    context 'with another staging location' do
      it 'returns the filepath within that location' do
        expect(described_class.staging_filepath(druid:, filepath: 'images/image1.tif',
                                                staging_location: Settings.assembly_location))
          .to eq(File.join(Settings.assembly_location, 'bc/123/df/4567/bc123df4567/content/images/image1.tif'))
      end
    end
  end

  describe '.delete_staged_files' do
    before do
      described_class.locations.each { |staging_location| stage_file(staging_location:) }
    end

    it 'deletes the staged files in every staging location' do
      described_class.delete_staged_files(druid:)

      expect(Dir.glob('**/*', base: File.join(Settings.staging_location, 'bc/123/df/4567/bc123df4567'))).to eq []
      expect(Dir.glob('**/*', base: File.join(Settings.assembly_location, 'bc/123/df/4567/bc123df4567'))).to eq []
    end
  end

  describe '.ensure_staging_folder' do
    # A druid of its own, since its folders are deleted while other specs may stage files in parallel.
    let(:druid) { 'druid:zy987wx6543' }

    def delete_druid_folders
      described_class.locations.each do |staging_location|
        FileUtils.rm_rf(DruidTools::Druid.new(druid, staging_location).path)
      end
    end

    before { delete_druid_folders }
    after { delete_druid_folders }

    context 'when no staging location has the druid folder' do
      it 'creates the staging content directory' do
        described_class.ensure_staging_folder(druid:)

        expect(File.directory?(described_class.staging_content_path(druid:))).to be true
      end
    end

    context 'when the assembly location has the druid folder' do
      before { stage_file(staging_location: Settings.assembly_location) }

      it 'does not create the staging content directory' do
        described_class.ensure_staging_folder(druid:)

        expect(File.exist?(described_class.staging_content_path(druid:))).to be false
      end
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
        FileUtils.mkdir_p(File.join(described_class.staging_content_path(druid:), 'images'))
      end

      it 'returns false' do
        expect(described_class.staged_files?(druid:)).to be false
      end
    end

    context 'when the staging content directory contains a file in a subdirectory' do
      before { stage_file(staging_location: Settings.staging_location) }

      it 'returns true' do
        expect(described_class.staged_files?(druid:)).to be true
      end
    end

    context 'when the assembly location contains a file' do
      before { stage_file(staging_location: Settings.assembly_location) }

      it 'returns true' do
        expect(described_class.staged_files?(druid:)).to be true
      end
    end
  end

  describe '.staged_location' do
    context 'when no files are staged' do
      it 'returns nil' do
        expect(described_class.staged_location(druid:)).to be_nil
      end
    end

    context 'when files are staged in the assembly location' do
      before { stage_file(staging_location: Settings.assembly_location) }

      it 'returns the assembly location' do
        expect(described_class.staged_location(druid:)).to eq(Settings.assembly_location)
      end
    end
  end
end
