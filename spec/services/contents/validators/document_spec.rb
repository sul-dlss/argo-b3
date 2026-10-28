# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Validators::Document do
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

  context 'when the document and file resources are valid' do
    before do
      create_resource(file_set_type: 'document', label: 'Document 1',
                      files: [['report.pdf', 'application/pdf', true], ['report.docx', 'application/msword', true],
                              ['report.txt', 'text/plain', false]])
      create_resource(file_set_type: 'file', label: 'File 1', files: [['data.zip', 'application/zip', true]])
      create_resource(file_set_type: 'image', label: 'Image 1', files: [['image1.tif', 'image/tiff', false]])
    end

    it 'has no errors or warnings' do
      expect(result).to have_attributes(errors: [], warnings: [])
    end
  end

  context 'when a document resource has more than one published PDF' do
    before do
      create_resource(file_set_type: 'document', label: 'Document 1',
                      files: [['report.pdf', 'application/pdf', true], ['draft.pdf', 'application/pdf', true]])
    end

    it 'has an error' do
      expect(result.errors).to eq(['Resource 1 (Document 1) has more than one published PDF file.'])
    end
  end

  context 'when a document resource has published files but no published PDF' do
    before do
      create_resource(file_set_type: 'document', label: 'Document 1',
                      files: [['report.pdf', 'application/pdf', false], ['notes.txt', 'text/plain', true]])
    end

    it 'has an error' do
      expect(result.errors).to eq(['Resource 1 (Document 1) has published files but no published PDF file.'])
    end
  end

  context 'when a file resource has more than one published file' do
    before do
      create_resource(file_set_type: 'document', label: 'Document 1', files: [['report.pdf', 'application/pdf', true]])
      create_resource(file_set_type: 'file', label: 'File 1',
                      files: [['data.zip', 'application/zip', true], ['notes.txt', 'text/plain', true]])
    end

    it 'has an error' do
      expect(result.errors).to eq(['Resource 2 (File 1) has more than one published file.'])
    end
  end

  context 'when a resource that is not a document or file resource has published files' do
    before do
      create_resource(file_set_type: 'document', label: 'Document 1', files: [['report.pdf', 'application/pdf', true]])
      create_resource(file_set_type: 'image', label: 'Image 1', files: [['image1.jp2', 'image/jp2', true]])
    end

    it 'has an error' do
      expect(result.errors).to eq(['Resource 2 (Image 1) has published files but is not a document or file resource.'])
    end
  end

  context 'when a resource has a blank label' do
    before do
      create_resource(file_set_type: 'document', label: '',
                      files: [['report.pdf', 'application/pdf', true], ['draft.pdf', 'application/pdf', true]])
    end

    it 'names the resource without a label' do
      expect(result.errors).to eq(['Resource 1 has more than one published PDF file.'])
    end
  end

  context 'when dark' do
    let(:dark) { true }

    before do
      create_resource(file_set_type: 'document', label: 'Document 1',
                      files: [['report.pdf', 'application/pdf', true], ['draft.pdf', 'application/pdf', true]])
      create_resource(file_set_type: 'image', label: 'Image 1', files: [['image1.jp2', 'image/jp2', true]])
    end

    it 'has warnings instead of errors' do
      expect(result).to have_attributes(
        errors: [],
        warnings: ['Resource 1 (Document 1) has more than one published PDF file.',
                   'Resource 2 (Image 1) has published files but is not a document or file resource.',
                   'No document resource has exactly one PDF file.']
      )
    end
  end

  context 'when there are no document resources' do
    before do
      create_resource(file_set_type: 'file', label: 'File 1', files: [['report.pdf', 'application/pdf', true]])
    end

    it 'has a warning but no errors' do
      expect(result).to have_attributes(errors: [], warnings: ['No document resource has exactly one PDF file.'])
    end
  end

  context 'when the document resource has more than one PDF file' do
    before do
      create_resource(file_set_type: 'document', label: 'Document 1',
                      files: [['report.pdf', 'application/pdf', true], ['draft.pdf', 'application/pdf', false]])
    end

    it 'has a warning but no errors' do
      expect(result).to have_attributes(errors: [], warnings: ['No document resource has exactly one PDF file.'])
    end
  end

  context 'when the document resource has no PDF file' do
    before do
      create_resource(file_set_type: 'document', label: 'Document 1',
                      files: [['report.docx', 'application/msword', false]])
    end

    it 'has a warning but no errors' do
      expect(result).to have_attributes(errors: [], warnings: ['No document resource has exactly one PDF file.'])
    end
  end
end
