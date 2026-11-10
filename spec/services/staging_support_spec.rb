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

  describe '.delete_staged_files_except' do
    let(:content_path) { described_class.staging_content_path(druid:) }

    before do
      %w[kept.tif folder1/kept.tif folder1/deleted.tif folder2/sub/deleted.tif].each do |filepath|
        full_path = File.join(content_path, filepath)
        FileUtils.mkdir_p(File.dirname(full_path))
        FileUtils.touch(full_path)
      end
      FileUtils.mkdir_p(File.join(content_path, 'empty'))
    end

    it 'deletes the other staged files and the directories left empty' do
      described_class.delete_staged_files_except(druid:, filepaths: %w[kept.tif folder1/kept.tif],
                                                 staging_location: Settings.staging_location)

      expect(Dir.glob('**/*', base: content_path)).to contain_exactly('kept.tif', 'folder1', 'folder1/kept.tif')
    end
  end

  describe '.stages_to_assembly?' do
    it 'is true for geo objects and web archive seeds only' do
      expect(described_class.stages_to_assembly?(build(:dro, type: Cocina::Models::ObjectType.geo))).to be true
      expect(described_class.stages_to_assembly?(build(:dro, type: Cocina::Models::ObjectType.webarchive_seed)))
        .to be true
      expect(described_class.stages_to_assembly?(build(:dro, type: Cocina::Models::ObjectType.image))).to be false
    end
  end

  describe '.location_for' do
    it 'is the assembly location for objects that stage there, otherwise the deposit staging location' do
      expect(described_class.location_for(cocina_object: build(:dro, type: Cocina::Models::ObjectType.geo)))
        .to eq Settings.assembly_location
      expect(described_class.location_for(cocina_object: build(:dro, type: Cocina::Models::ObjectType.image)))
        .to eq Settings.staging_location
    end
  end

  describe '.ensure_staging_folder' do
    # A druid of its own, since its folders are deleted while other specs may stage files in parallel.
    let(:druid) { 'druid:zy987wx6543' }
    let(:cocina_object) { build(:dro, id: druid) }

    def delete_druid_folders
      described_class.locations.each do |staging_location|
        FileUtils.rm_rf(DruidTools::Druid.new(druid, staging_location).path)
      end
    end

    before { delete_druid_folders }
    after { delete_druid_folders }

    context 'when no staging location has the druid folder' do
      it 'creates the staging content directory' do
        described_class.ensure_staging_folder(cocina_object:)

        expect(File.directory?(described_class.staging_content_path(druid:))).to be true
      end
    end

    context 'when the object is a web archive seed' do
      let(:cocina_object) { build(:dro, id: druid, type: Cocina::Models::ObjectType.webarchive_seed) }

      it 'creates the staging content directory in the assembly location' do
        described_class.ensure_staging_folder(cocina_object:)

        expect(File.directory?(described_class.staging_content_path(druid:,
                                                                    staging_location: Settings.assembly_location)))
          .to be true
        expect(File.exist?(DruidTools::Druid.new(druid, Settings.staging_location).path)).to be false
      end
    end

    context 'when the assembly location has the druid folder' do
      before { stage_file(staging_location: Settings.assembly_location) }

      it 'does not create the staging content directory' do
        described_class.ensure_staging_folder(cocina_object:)

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

  describe '.move_to_assembly' do
    let(:assembly_filepath) do
      File.join(Settings.assembly_location, 'bc/123/df/4567/bc123df4567/content/images/image1.tif')
    end

    context 'when files are staged in the deposit staging location' do
      before { stage_file(staging_location: Settings.staging_location) }

      it 'moves them to the assembly location' do
        described_class.move_to_assembly(druid:)

        expect(File.exist?(assembly_filepath)).to be true
        expect(File.exist?(File.join(Settings.staging_location, 'bc/123/df/4567/bc123df4567'))).to be false
      end
    end

    context 'when files are also staged in the assembly location' do
      let(:existing_assembly_filepath) do
        File.join(Settings.assembly_location, 'bc/123/df/4567/bc123df4567/content/existing.tif')
      end

      before do
        stage_file(staging_location: Settings.staging_location)
        FileUtils.mkdir_p(File.dirname(existing_assembly_filepath))
        FileUtils.touch(existing_assembly_filepath)
      end

      it 'replaces the files in the assembly location' do
        described_class.move_to_assembly(druid:)

        expect(File.exist?(assembly_filepath)).to be true
        expect(File.exist?(existing_assembly_filepath)).to be false
      end
    end

    context 'when no files are staged in the deposit staging location' do
      before { stage_file(staging_location: Settings.assembly_location) }

      it 'leaves the assembly location unchanged' do
        described_class.move_to_assembly(druid:)

        expect(File.exist?(assembly_filepath)).to be true
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
