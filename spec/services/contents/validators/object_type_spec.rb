# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Validators::ObjectType do
  subject(:result) { described_class.call(content:, dark:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:dark) { false }

  # @param [Array<Array>] files the filepath and publish flag of each file
  def create_resource(file_set_type:, files:, label: '')
    position = content.content_file_sets.count + 1
    content_file_set = create(:content_file_set, content:, file_set_type:, label:, position:)
    files.each.with_index(1) do |(filepath, publish), file_position|
      content_file_binary = create(:content_file_binary, content:, filepath:)
      create(:content_file, content_file_set:, content_file_binary:, position: file_position, label: filepath,
                            publish:, shelve: publish)
    end
  end

  context 'when the file resources are valid' do
    before do
      create_resource(file_set_type: 'file', label: 'File 1', files: [['data.zip', true], ['notes.txt', false]])
      create_resource(file_set_type: 'file', label: 'File 2', files: [['data2.zip', true]])
      create_resource(file_set_type: 'image', label: 'Image 1', files: [['image1.tif', false]])
    end

    it 'has no errors or warnings' do
      expect(result).to have_attributes(errors: [], warnings: [])
    end
  end

  context 'when a resource has more than one published file' do
    before do
      create_resource(file_set_type: 'file', label: 'File 1', files: [['data.zip', true], ['notes.txt', true]])
    end

    it 'has an error' do
      expect(result.errors).to eq(['Resource 1 (File 1) has more than one published file.'])
    end
  end

  context 'when a resource that is not a file resource has published files' do
    before do
      create_resource(file_set_type: 'file', label: 'File 1', files: [['data.zip', true]])
      create_resource(file_set_type: 'image', label: 'Image 1', files: [['image1.jp2', true]])
    end

    it 'has an error' do
      expect(result.errors).to eq(['Resource 2 (Image 1) has published files but is not a file resource.'])
    end
  end

  context 'when a resource has a blank label' do
    before do
      create_resource(file_set_type: 'file', label: '', files: [['data.zip', true], ['notes.txt', true]])
    end

    it 'names the resource without a label' do
      expect(result.errors).to eq(['Resource 1 has more than one published file.'])
    end
  end

  context 'when dark' do
    let(:dark) { true }

    before do
      create_resource(file_set_type: 'file', label: 'File 1', files: [['data.zip', true], ['notes.txt', true]])
      create_resource(file_set_type: 'image', label: 'Image 1', files: [['image1.jp2', true]])
    end

    it 'has warnings instead of errors' do
      expect(result).to have_attributes(
        errors: [],
        warnings: ['Resource 1 (File 1) has more than one published file.',
                   'Resource 2 (Image 1) has published files but is not a file resource.']
      )
    end
  end

  context 'when there are no file resources' do
    before do
      create_resource(file_set_type: 'image', label: 'Image 1', files: [['image1.tif', false]])
    end

    it 'has a warning but no errors' do
      expect(result).to have_attributes(errors: [], warnings: ['There are no file resources.'])
    end
  end
end
