# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Populators::Image do
  subject(:structure) { described_class.structure(content:, cocina_object:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:cocina_object) do
    build(:dro_with_metadata, id: content.druid).new(access: { view: 'world', download: 'world' })
  end

  describe '.structure' do
    context 'when an image has a master and a deliverable' do
      let!(:tiff_binary) do
        create(:content_file_binary, content:, filepath: 'image_0001.tif', mime_type: 'image/tiff')
      end
      let!(:jp2_binary) do
        create(:content_file_binary, content:, filepath: 'image_0001.jp2', mime_type: 'image/jp2')
      end

      it 'creates a single image file set' do
        structure

        expect(content.content_file_sets.sole).to have_attributes(file_set_type: 'image', label: 'Image 1')
      end

      it 'creates a file per binary with attributes for its mime type' do
        structure

        content_files = content.content_file_sets.sole.content_files
        expect(content_files.map(&:content_file_binary)).to eq([jp2_binary, tiff_binary])
        expect(content_files.first).to have_attributes(label: 'image_0001.jp2', preserve: false, shelve: true,
                                                       publish: true, use: nil,
                                                       view: cocina_object.access.view,
                                                       download: cocina_object.access.download,
                                                       location: cocina_object.access.location)
        expect(content_files.second).to have_attributes(label: 'image_0001.tif', preserve: true, shelve: false,
                                                        publish: false, use: nil)
      end
    end

    context 'when an image also has OCR' do
      before do
        create(:content_file_binary, content:, filepath: 'image_0001.tif', mime_type: 'image/tiff')
        create(:content_file_binary, content:, filepath: 'image_0001.jp2', mime_type: 'image/jp2')
        create(:content_file_binary, content:, filepath: 'image_0001.xml', mime_type: 'application/xml')
      end

      it 'groups the OCR into the same file set' do
        structure

        expect(content.content_file_sets.sole).to have_attributes(file_set_type: 'image', label: 'Image 1')
        expect(content.content_files.map(&:filepath)).to eq(%w[image_0001.jp2 image_0001.tif image_0001.xml])
      end

      it 'preserves the deliverable and marks the OCR as a transcription' do
        structure

        expect(content.content_files.find_by(label: 'image_0001.jp2')).to have_attributes(preserve: true, shelve: true,
                                                                                          publish: true)
        expect(content.content_files.find_by(label: 'image_0001.xml'))
          .to have_attributes(preserve: true, shelve: true, publish: true, use: 'transcription',
                              corrected_for_accessibility: false)
      end
    end

    context 'when an image also has TXT, HTML, PDF, and JSON files' do
      before do
        create(:content_file_binary, content:, filepath: 'image_0001.tif', mime_type: 'image/tiff')
        create(:content_file_binary, content:, filepath: 'image_0001.txt', mime_type: 'text/plain')
        create(:content_file_binary, content:, filepath: 'image_0001.html', mime_type: 'text/html')
        create(:content_file_binary, content:, filepath: 'image_0001.pdf', mime_type: 'application/pdf')
        create(:content_file_binary, content:, filepath: 'image_0001.json', mime_type: 'application/json')
      end

      it 'groups the files into the same file set' do
        structure

        expect(content.content_file_sets.sole).to have_attributes(file_set_type: 'image', label: 'Image 1')
        expect(content.content_files.map(&:filepath))
          .to eq(%w[image_0001.html image_0001.json image_0001.pdf image_0001.tif image_0001.txt])
      end

      it 'preserves and publishes the extra files (other than the image)' do
        structure

        %w[image_0001.txt image_0001.html image_0001.pdf image_0001.json].each do |label|
          expect(content.content_files.find_by(label:)).to have_attributes(preserve: true, shelve: true, publish: true)
        end
      end

      it 'marks the TXT, HTML, and PDF as transcriptions and the JSON as annotations' do
        structure

        expect(content.content_files.pluck(:label, :use)).to contain_exactly(
          %w[image_0001.html transcription], %w[image_0001.json annotations], %w[image_0001.pdf transcription],
          ['image_0001.tif', nil], %w[image_0001.txt transcription]
        )
      end
    end

    context 'when an image has only a JSON file and a JP2 file' do
      before do
        create(:content_file_binary, content:, filepath: 'image_0001.jp2', mime_type: 'image/jp2')
        create(:content_file_binary, content:, filepath: 'image_0001.json', mime_type: 'application/json')
      end

      it 'marks the JSON as annotations without treating the file set as containing OCR' do
        structure

        expect(content.content_files.find_by(label: 'image_0001.json'))
          .to have_attributes(preserve: true, shelve: true, publish: true, use: 'annotations')
        expect(content.content_files.find_by(label: 'image_0001.jp2')).to have_attributes(preserve: false)
      end
    end

    context 'when a JSON file does not share a basename with an image' do
      before do
        create(:content_file_binary, content:, filepath: 'image_0001.jp2', mime_type: 'image/jp2')
        create(:content_file_binary, content:, filepath: 'notes.json', mime_type: 'application/json')
      end

      it 'places it in its own file set without marking it as annotations' do
        structure

        expect(content.content_files.find_by(label: 'notes.json').content_file_set)
          .to have_attributes(file_set_type: 'object')
        expect(content.content_files.find_by(label: 'notes.json')).to have_attributes(use: nil)
      end
    end

    context 'when an image has a TXT file and a JP2 file' do
      before do
        create(:content_file_binary, content:, filepath: 'image_0001.jp2', mime_type: 'image/jp2')
        create(:content_file_binary, content:, filepath: 'image_0001.txt', mime_type: 'text/plain')
      end

      it 'publishes the TXT as a transcription and preserves the deliverable JP2' do
        structure

        expect(content.content_files.find_by(label: 'image_0001.jp2')).to have_attributes(preserve: true)
        expect(content.content_files.find_by(label: 'image_0001.txt'))
          .to have_attributes(preserve: true, shelve: true, publish: true, use: 'transcription')
      end
    end

    context 'when there are multiple images' do
      before do
        create(:content_file_binary, content:, filepath: 'image_0002.tif', mime_type: 'image/tiff')
        create(:content_file_binary, content:, filepath: 'image_0001.tif', mime_type: 'image/tiff')
      end

      it 'creates a file set per image in filepath order rather than creation order' do
        structure

        expect(content.content_file_sets.map(&:label)).to eq(['Image 1', 'Image 2'])
        expect(content.content_file_sets.pluck(:position)).to eq([1, 2])
        expect(content.content_files.map(&:filepath)).to eq(%w[image_0001.tif image_0002.tif])
      end
    end

    context 'when a file set contains no images' do
      before do
        # Sorts before the images by filepath, but is placed after them because it is not an image.
        create(:content_file_binary, content:, filepath: 'aaa_notes.pdf', mime_type: 'application/pdf')
        create(:content_file_binary, content:, filepath: 'image_0001.tif', mime_type: 'image/tiff')
        create(:content_file_binary, content:, filepath: 'image_0002.tif', mime_type: 'image/tiff')
      end

      it 'types it as an object, places it after the images, and numbers its label separately' do
        structure

        expect(content.content_file_sets.map { |file_set| [file_set.file_set_type, file_set.label] })
          .to eq([['image', 'Image 1'], ['image', 'Image 2'], ['object', 'Object 1']])
        expect(content.content_files.map(&:filepath)).to eq(%w[image_0001.tif image_0002.tif aaa_notes.pdf])
      end

      it 'does not treat the PDF as a transcription' do
        structure

        expect(content.content_files.find_by(label: 'aaa_notes.pdf')).to have_attributes(use: nil)
      end
    end

    context 'when a binary has no mime type' do
      before do
        create(:content_file_binary, content:, filepath: 'unknown.bin', mime_type: nil)
      end

      it 'treats it as a non-image with the default attributes' do
        structure

        expect(content.content_file_sets.sole).to have_attributes(file_set_type: 'object', label: 'Object 1')
        expect(content.content_files.sole).to have_attributes(preserve: true, shelve: false, publish: false, use: nil)
      end
    end

    context 'when the object is dark' do
      let(:cocina_object) do
        build(:dro_with_metadata, id: content.druid).new(access: { view: 'dark', download: 'none' })
      end

      before do
        create(:content_file_binary, content:, filepath: 'image_0001.jp2', mime_type: 'image/jp2')
        create(:content_file_binary, content:, filepath: 'image_0001.xml', mime_type: 'application/xml')
      end

      it 'preserves but does not shelve or publish the files, retaining the transcription use' do
        structure

        expect(content.content_files.find_by(label: 'image_0001.jp2'))
          .to have_attributes(preserve: true, shelve: false, publish: false, use: nil, view: 'dark')
        expect(content.content_files.find_by(label: 'image_0001.xml'))
          .to have_attributes(preserve: true, shelve: false, publish: false, use: 'transcription', view: 'dark')
      end
    end

    context 'when the object is embargoed' do
      let(:cocina_object) do
        build(:dro_with_metadata, id: content.druid).new(
          access: {
            view: 'citation-only',
            download: 'none',
            embargo: {
              releaseDate: DateTime.parse('2040-06-15T19:00:00Z'),
              view: 'stanford',
              download: 'stanford'
            }
          }
        )
      end

      before do
        create(:content_file_binary, content:, filepath: 'image_0001.tif', mime_type: 'image/tiff')
      end

      it 'uses the embargo access settings' do
        structure

        expect(content.content_files.sole).to have_attributes(view: 'stanford', download: 'stanford')
      end
    end

    context 'when restructuring an image that has presentation metadata' do
      let(:jp2_binary) do
        create(:content_file_binary, content:, filepath: 'image_0001.jp2', mime_type: 'image/jp2',
                                     height: 6561, width: 4420)
      end

      before do
        create(:content_file, content_file_set: create(:content_file_set, content:), content_file_binary: jp2_binary)
      end

      it 'retains the height and width' do
        structure

        expect(content.content_files.sole).to have_attributes(content_file_binary: jp2_binary, height: 6561,
                                                              width: 4420)
      end
    end
  end

  describe '.append' do
    subject(:append) { described_class.append(content:, cocina_object:) }

    let(:existing_content_file_set) do
      create(:content_file_set, content:, file_set_type: 'image', label: 'Image 1', position: 1)
    end
    let!(:existing_content_file_binary) do
      create(:content_file_binary, content:, filepath: 'image_0001.jp2', mime_type: 'image/jp2')
    end

    before do
      # The attributes that structuring gives a deliverable image in a file set without OCR.
      create(:content_file, content_file_set: existing_content_file_set,
                            content_file_binary: existing_content_file_binary, label: 'image_0001.jp2',
                            preserve: false, shelve: true, publish: true)
    end

    context 'when the new binary belongs to an existing file set' do
      let!(:appended_content_file_binary) do
        create(:content_file_binary, content:, filepath: 'image_0001.xml', mime_type: 'application/xml')
      end

      it 'adds it to the existing file set without changing the file set' do
        append

        expect(content.content_file_sets.sole).to have_attributes(file_set_type: 'image', label: 'Image 1', position: 1)
        expect(content.content_files.map(&:content_file_binary))
          .to eq([existing_content_file_binary, appended_content_file_binary])
      end

      it 'treats the file set as containing OCR' do
        append

        expect(content.content_files.find_by(label: 'image_0001.xml'))
          .to have_attributes(preserve: true, shelve: true, publish: true, use: 'transcription')
      end

      it 'updates the existing files for the file set now containing OCR' do
        append

        expect(content.content_files.find_by(label: 'image_0001.jp2'))
          .to have_attributes(preserve: true, shelve: true, publish: true)
      end
    end

    context 'when the new binary is annotations for an existing file set' do
      before do
        create(:content_file_binary, content:, filepath: 'image_0001.json', mime_type: 'application/json')
      end

      it 'marks it as annotations and leaves the existing files alone' do
        append

        expect(content.content_files.find_by(label: 'image_0001.json'))
          .to have_attributes(preserve: true, shelve: true, publish: true, use: 'annotations')
        expect(content.content_files.find_by(label: 'image_0001.jp2'))
          .to have_attributes(preserve: false, shelve: true, publish: true)
      end
    end

    context 'when the new binary is an image for an existing file set that contains annotations' do
      let(:existing_content_file_set) do
        create(:content_file_set, content:, file_set_type: 'object', label: 'Object 1', position: 1)
      end
      let!(:existing_content_file_binary) do
        create(:content_file_binary, content:, filepath: 'image_0001.json', mime_type: 'application/json')
      end

      before do
        create(:content_file_binary, content:, filepath: 'image_0001.jp2', mime_type: 'image/jp2')
      end

      it 'updates the existing JSON to be annotations' do
        append

        expect(content.content_files.find_by(content_file_binary: existing_content_file_binary))
          .to have_attributes(preserve: true, shelve: true, publish: true, use: 'annotations')
      end
    end

    context 'when the object is dark and the new binary makes the file set contain OCR' do
      let(:cocina_object) do
        build(:dro_with_metadata, id: content.druid).new(access: { view: 'dark', download: 'none' })
      end

      before do
        create(:content_file_binary, content:, filepath: 'image_0001.xml', mime_type: 'application/xml')
      end

      it 'preserves but does not shelve or publish the new and existing files' do
        append

        expect(content.content_files.find_by(label: 'image_0001.xml'))
          .to have_attributes(preserve: true, shelve: false, publish: false)
        expect(content.content_files.find_by(label: 'image_0001.jp2'))
          .to have_attributes(preserve: true, shelve: false, publish: false)
      end
    end

    context 'when the new binary does not change whether the file set contains OCR' do
      before do
        create(:content_file_binary, content:, filepath: 'image_0001.tif', mime_type: 'image/tiff')
      end

      it 'leaves the existing files alone' do
        append

        expect(content.content_files.find_by(label: 'image_0001.jp2'))
          .to have_attributes(preserve: false, shelve: true, publish: true)
      end
    end

    context 'when the new binary does not belong to an existing file set' do
      before do
        create(:content_file_binary, content:, filepath: 'image_0002.jp2', mime_type: 'image/jp2')
      end

      it 'creates a file set at the end, continuing the label numbering' do
        append

        expect(content.content_file_sets.map(&:label)).to eq(['Image 1', 'Image 2'])
        expect(content.content_file_sets.pluck(:position)).to eq([1, 2])
      end
    end

    context 'when multiple new binaries share a basename' do
      before do
        create(:content_file_binary, content:, filepath: 'image_0002.tif', mime_type: 'image/tiff')
        create(:content_file_binary, content:, filepath: 'image_0002.jp2', mime_type: 'image/jp2')
      end

      it 'groups them into a single new file set' do
        append

        expect(content.content_file_sets.count).to eq(2)
        expect(content.content_file_sets.last.content_files.map(&:filepath)).to eq(%w[image_0002.jp2 image_0002.tif])
      end
    end

    context 'when more than one existing file set matches the basename' do
      let!(:other_content_file_set) do
        create(:content_file_set, content:, file_set_type: 'image', label: 'Image 2', position: 2)
      end

      before do
        create(:content_file, content_file_set: other_content_file_set,
                              content_file_binary: create(:content_file_binary, content:, filepath: 'image_0001.tif',
                                                                                mime_type: 'image/tiff'),
                              label: 'image_0001.tif')
        create(:content_file_binary, content:, filepath: 'image_0001.xml', mime_type: 'application/xml')
      end

      it 'adds it to the file set with the lowest position' do
        append

        expect(existing_content_file_set.content_files.map(&:label)).to eq(['image_0001.jp2', 'image_0001.xml'])
        expect(other_content_file_set.content_files.map(&:label)).to eq(['image_0001.tif'])
      end
    end
  end
end
