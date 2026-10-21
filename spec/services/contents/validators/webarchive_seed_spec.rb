# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Validators::WebarchiveSeed do
  subject(:result) { described_class.call(content:, dark:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:dark) { false }

  # @param [Array<Array>] files the filepath, mime type, and publish flag of each file
  def create_resource(files:, file_set_type: 'image', label: '')
    position = content.content_file_sets.count + 1
    content_file_set = create(:content_file_set, content:, file_set_type:, label:, position:)
    files.each.with_index(1) do |(filepath, mime_type, publish), file_position|
      content_file_binary = create(:content_file_binary, content:, filepath:, mime_type:)
      create(:content_file, content_file_set:, content_file_binary:, position: file_position, label: filepath,
                            publish:, shelve: publish)
    end
  end

  context 'with one published JP2 and unpublished source files' do
    before do
      create_resource(files: [['thumbnail.jp2', 'image/jp2', true], ['source.tif', 'image/tiff', false],
                              ['other.jp2', 'image/jp2', false]])
      create_resource(file_set_type: 'file', files: [['metadata.xml', 'application/xml', false]])
    end

    it 'has no errors or warnings' do
      expect(result).to have_attributes(errors: [], warnings: [])
    end
  end

  context 'without published files' do
    before { create_resource(files: [['source.jpg', 'image/jpeg', false]]) }

    it 'has no errors or warnings' do
      expect(result).to have_attributes(errors: [], warnings: [])
    end
  end

  context 'with multiple published JP2 files in one resource' do
    before do
      create_resource(files: [['thumbnail.jp2', 'image/jp2', true], ['other.jp2', 'image/jp2', true]])
    end

    it 'has an error' do
      expect(result).to have_attributes(errors: ['There is more than one published JP2 file.'], warnings: [])
    end
  end

  context 'with published JP2 files in different resources' do
    before do
      create_resource(files: [['thumbnail.jp2', 'image/jp2', true]])
      create_resource(file_set_type: 'file', files: [['other.jp2', 'image/jp2', true]])
    end

    it 'has an error across resources' do
      expect(result).to have_attributes(errors: ['There is more than one published JP2 file.'], warnings: [])
    end
  end

  context 'with published files other than JP2' do
    before do
      create_resource(label: 'Thumbnail', files: [['thumbnail.jp2', 'image/jp2', true],
                                                  ['source.png', 'image/png', true], ['unknown.dat', nil, true],
                                                  ['metadata.xml', 'application/xml', false]])
      create_resource(file_set_type: 'object', files: [['notes.txt', 'text/plain', true]])
    end

    it 'lists only unsupported published files, regardless of resource type' do
      expect(result).to have_attributes(
        errors: ['Resource 1 (Thumbnail) has published files that are not JP2: source.png, unknown.dat.',
                 'Resource 2 has published files that are not JP2: notes.txt.'], warnings: []
      )
    end
  end

  context 'when dark' do
    let(:dark) { true }

    before do
      create_resource(label: 'Thumbnail', files: [['thumbnail.jp2', 'image/jp2', true],
                                                  ['other.jp2', 'image/jp2', true], ['source.jpg', 'image/jpeg', true]])
    end

    it 'has warnings instead of errors for every violation' do
      expect(result).to have_attributes(
        errors: [], warnings: ['Resource 1 (Thumbnail) has published files that are not JP2: source.jpg.',
                               'There is more than one published JP2 file.']
      )
    end
  end
end
