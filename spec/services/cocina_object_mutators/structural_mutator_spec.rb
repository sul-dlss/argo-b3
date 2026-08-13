# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CocinaObjectMutators::StructuralMutator do
  subject(:mutated_cocina_object) { described_class.call(cocina_object:, content:) }

  let(:cocina_object) do
    dro_with_metadata = build(:dro_with_metadata)
    dro_with_metadata.new(access: dro_with_metadata.access.new(view: 'world', download: 'world'))
  end

  context 'when the cocina_object is not a DRO' do
    let(:cocina_object) { build(:collection_with_metadata) }
    let(:content) { create(:content) }

    it 'raises' do
      expect { mutated_cocina_object }.to raise_error(
        ArgumentError, 'Expected a Cocina::Models::DRO or Cocina::Models::DROWithMetadata'
      )
    end
  end

  context 'with no ContentFileSets' do
    let(:content) { create(:content) }

    it 'builds an empty structural.contains' do
      expect(mutated_cocina_object.structural.contains).to eq([])
    end
  end

  context 'with ContentFileSets and ContentFiles' do
    let(:content) { create(:content) }

    let(:first_content_file_set) do
      create(:content_file_set, content:, position: 1, file_set_type: 'image', label: 'Image 1',
                                external_identifier: 'https://cocina.sul.stanford.edu/fileSet/first')
    end
    let(:second_content_file_set) do
      create(:content_file_set, content:, position: 2, file_set_type: 'page', label: 'Page 1',
                                external_identifier: 'https://cocina.sul.stanford.edu/fileSet/second')
    end

    before do
      create(:content_file, content_file_set: first_content_file_set, position: 1,
                            label: 'Image 1 file', filepath: 'folder1/image1.tif',
                            external_identifier: 'https://cocina.sul.stanford.edu/file/first',
                            size: 12_345, mime_type: 'image/tiff', md5_digest: 'md5digest', sha1_digest: 'sha1digest',
                            file_location: 'deposited',
                            language_tag: 'en', use: 'transcription',
                            sdr_generated_text: true, corrected_for_accessibility: true,
                            view: 'location-based', download: 'location-based', location: 'music',
                            publish: true, preserve: false, shelve: true,
                            height: 5833, width: 4001)
      create(:content_file, content_file_set: second_content_file_set, position: 1,
                            label: 'Page 1 file', filepath: 'image2.tif',
                            external_identifier: 'https://cocina.sul.stanford.edu/file/second',
                            size: 543, mime_type: 'image/tiff', md5_digest: 'md5digest2', sha1_digest: 'sha1digest2',
                            file_location: 'deposited',
                            view: 'world', download: 'world', publish: false, preserve: true, shelve: false)
    end

    it 'rebuilds structural.contains from the Content' do
      file_sets = mutated_cocina_object.structural.contains
      expect(file_sets.size).to eq(2)

      first_file_set = file_sets.first
      expect(first_file_set).to have_attributes(
        type: 'https://cocina.sul.stanford.edu/models/resources/image',
        externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/first',
        label: 'Image 1',
        version: cocina_object.version
      )

      first_file = first_file_set.structural.contains.sole
      expect(first_file).to have_attributes(
        type: Cocina::Models::ObjectType.file,
        externalIdentifier: 'https://cocina.sul.stanford.edu/file/first',
        label: 'Image 1 file',
        filename: 'folder1/image1.tif',
        version: cocina_object.version,
        size: 12_345,
        hasMimeType: 'image/tiff',
        languageTag: 'en',
        use: 'transcription',
        sdrGeneratedText: true,
        correctedForAccessibility: true
      )
      expect(first_file.hasMessageDigests).to contain_exactly(
        Cocina::Models::MessageDigest.new(type: 'md5', digest: 'md5digest'),
        Cocina::Models::MessageDigest.new(type: 'sha1', digest: 'sha1digest')
      )
      expect(first_file.access).to have_attributes(
        view: 'location-based', download: 'location-based', location: 'music'
      )
      expect(first_file.administrative).to have_attributes(publish: true, sdrPreserve: false, shelve: true)
      expect(first_file.presentation).to have_attributes(height: 5833, width: 4001)

      second_file_set = file_sets.second
      expect(second_file_set).to have_attributes(
        type: 'https://cocina.sul.stanford.edu/models/resources/page',
        externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/second',
        label: 'Page 1'
      )

      second_file = second_file_set.structural.contains.sole
      expect(second_file).to have_attributes(filename: 'image2.tif', size: 543, hasMimeType: 'image/tiff')
      expect(second_file.presentation).to be_nil
    end
  end

  context 'when a ContentFileSet is not valid for deposit' do
    let(:content) { create(:content) }
    let(:content_file_set) { create(:content_file_set, content:, external_identifier: nil) }

    before do
      create(:content_file, content_file_set:, external_identifier: 'https://cocina.sul.stanford.edu/file/first',
                            size: 543, mime_type: 'image/tiff', md5_digest: 'md5digest', sha1_digest: 'sha1digest',
                            file_location: 'deposited')
    end

    it 'raises' do
      expect { mutated_cocina_object }.to raise_error(ActiveRecord::RecordInvalid, /blank/) do |error|
        expect(error.record).to eq(content_file_set)
      end
    end
  end

  context 'when a ContentFile is not valid for deposit' do
    let(:content) { create(:content) }
    let(:content_file_set) do
      create(:content_file_set, content:, external_identifier: 'https://cocina.sul.stanford.edu/fileSet/first')
    end
    let(:content_file) { create(:content_file, content_file_set:, external_identifier: nil, file_location: 'attached') }

    before { content_file }

    it 'raises with the errors for the invalid ContentFile' do
      expect { mutated_cocina_object }.to raise_error(ActiveRecord::RecordInvalid) do |error|
        expect(error.record).to eq(content_file)
        expect(error.message).to include(
          "External identifier can't be blank", "Mime type can't be blank", "Size can't be blank",
          "Md5 digest can't be blank", "Sha1 digest can't be blank", 'File location is not included in the list'
        )
      end
    end
  end
end
