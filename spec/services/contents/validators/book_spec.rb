# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Validators::Book do
  subject(:result) { described_class.call(content:, dark:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:dark) { false }

  # @param [Array<Array>] files the filepath, mime type, and publish flag of each file
  def create_resource(file_set_type:, files:, label: '')
    position = content.content_file_sets.count + 1
    content_file_set = create(:content_file_set, content:, file_set_type:, label:, position:)
    files.each.with_index(1) do |(filepath, mime_type, publish), file_position|
      content_file_binary = create(:content_file_binary, content:, filepath:, mime_type:)
      create(:content_file, content_file_set:, content_file_binary:, position: file_position, label: filepath,
                            publish:, shelve: publish)
    end
  end

  context 'when the pages are valid' do
    before do
      create_resource(file_set_type: 'page', label: 'Page 1',
                      files: [['page_0001.tif', 'image/tiff', false],
                              ['page_0001.jp2', 'image/jp2', true],
                              ['page_0001.xml', 'application/xml', true],
                              ['page_0001.txt', 'text/plain', true],
                              ['page_0001.html', 'text/html', true]])
      create_resource(file_set_type: 'object', label: 'Object 1', files: [['notes.pdf', 'application/pdf', true]])
      create_resource(file_set_type: 'file', label: 'File 1', files: [['data.zip', 'application/zip', false]])
    end

    it 'has no errors or warnings' do
      expect(result).to have_attributes(errors: [], warnings: [])
    end
  end

  context 'when a page has more than one published JP2' do
    before do
      create_resource(file_set_type: 'page', label: 'Page 1',
                      files: [['page_0001.jp2', 'image/jp2', true], ['page_0001a.jp2', 'image/jp2', true]])
    end

    it 'has an error' do
      expect(result.errors).to eq(['Resource 1 (Page 1) has more than one published JP2 file.'])
    end
  end

  context 'when a page has more than one JP2 but only one is published' do
    before do
      create_resource(file_set_type: 'page', label: 'Page 1',
                      files: [['page_0001.jp2', 'image/jp2', true], ['page_0001a.jp2', 'image/jp2', false]])
    end

    it 'has no errors' do
      expect(result.errors).to eq([])
    end
  end

  context 'when a page has more than one unpublished TIFF, PNG, or JPEG' do
    before do
      create_resource(file_set_type: 'page', label: 'Page 1',
                      files: [['page_0001.tif', 'image/tiff', false], ['page_0001.png', 'image/png', false]])
    end

    it 'has an error' do
      expect(result.errors).to eq(['Resource 1 (Page 1) has more than one TIFF, PNG, or JPEG file.'])
    end
  end

  context 'when a page has published files that are not JP2, XML, TXT, or HTML' do
    before do
      create_resource(file_set_type: 'page', label: 'Page 1',
                      files: [['page_0001.jp2', 'image/jp2', true],
                              ['page_0001.pdf', 'application/pdf', true],
                              ['page_0001.dat', nil, true],
                              ['page_0001.zip', 'application/zip', false]])
    end

    it 'has an error listing the files' do
      expect(result.errors).to eq(['Resource 1 (Page 1) has published files that are not JP2, XML, TXT, or HTML: ' \
                                   'page_0001.pdf, page_0001.dat.'])
    end
  end

  context 'when a resource that is not a page or object has published files' do
    before do
      create_resource(file_set_type: 'page', label: 'Page 1', files: [['page_0001.jp2', 'image/jp2', true]])
      create_resource(file_set_type: 'image', label: 'Image 1', files: [['image1.jp2', 'image/jp2', true]])
    end

    it 'has an error' do
      expect(result.errors).to eq(['Resource 2 (Image 1) has published files but is not a page or object resource.'])
    end
  end

  context 'when a resource that is not a page or object has a blank label' do
    before do
      create_resource(file_set_type: 'page', label: 'Page 1', files: [['page_0001.jp2', 'image/jp2', true]])
      create_resource(file_set_type: 'file', label: '', files: [['data.json', 'application/json', true]])
    end

    it 'names the resource without a label' do
      expect(result.errors).to eq(['Resource 2 has published files but is not a page or object resource.'])
    end
  end

  context 'when dark' do
    let(:dark) { true }

    before do
      create_resource(file_set_type: 'page', label: 'Page 1',
                      files: [['page_0001.jp2', 'image/jp2', true], ['page_0001a.jp2', 'image/jp2', true]])
      create_resource(file_set_type: 'file', label: 'File 1', files: [['data.json', 'application/json', true]])
    end

    it 'has warnings instead of errors' do
      expect(result).to have_attributes(
        errors: [],
        warnings: ['Resource 1 (Page 1) has more than one published JP2 file.',
                   'Resource 2 (File 1) has published files but is not a page or object resource.']
      )
    end
  end

  context 'when the only page image is an unpublished TIFF' do
    before do
      create_resource(file_set_type: 'page', label: 'Page 1', files: [['page_0001.tif', 'image/tiff', false]])
    end

    it 'has no warnings' do
      expect(result.warnings).to eq([])
    end
  end

  context 'when no page has a published JP2 or a TIFF, PNG, or JPEG' do
    before do
      create_resource(file_set_type: 'page', label: 'Page 1',
                      files: [['page_0001.jp2', 'image/jp2', false], ['page_0001.txt', 'text/plain', true]])
      create_resource(file_set_type: 'object', label: 'Object 1', files: [['image1.tif', 'image/tiff', false]])
    end

    it 'has a warning but no errors' do
      expect(result).to have_attributes(
        errors: [],
        warnings: ['No page resource has a published JP2 or a TIFF, PNG, or JPEG file.']
      )
    end
  end

  context 'when there are no resources' do
    it 'has a warning' do
      expect(result.warnings).to eq(['No page resource has a published JP2 or a TIFF, PNG, or JPEG file.'])
    end
  end
end
