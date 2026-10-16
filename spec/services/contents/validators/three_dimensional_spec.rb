# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Validators::ThreeDimensional do
  subject(:result) { described_class.call(content:, dark:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:dark) { false }
  let(:glb) { MimeTypes::GLTF_BINARY }
  let(:not_exactly_one_model_warning) { 'There is not exactly one 3D resource containing exactly one GLB file.' }

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

  context 'when the resources are valid' do
    before do
      create_resource(file_set_type: '3d', label: '3D 1', files: [['model.glb', glb, true]])
      create_resource(file_set_type: 'file', label: 'File 1', files: [['notes.txt', MimeTypes::PLAIN_TEXT, true]])
      create_resource(file_set_type: 'image', label: 'Image 1', files: [['image1.tif', MimeTypes::TIFF, false]])
    end

    it 'has no errors or warnings' do
      expect(result).to have_attributes(errors: [], warnings: [])
    end
  end

  context 'when a resource that is not a 3d or file resource has published files' do
    before do
      create_resource(file_set_type: '3d', label: '3D 1', files: [['model.glb', glb, true]])
      create_resource(file_set_type: 'image', label: 'Image 1', files: [['image1.jp2', MimeTypes::JP2, true]])
    end

    it 'has an error' do
      expect(result).to have_attributes(
        errors: ['Resource 2 (Image 1) has published files but is not a 3D or file resource.'], warnings: []
      )
    end
  end

  context 'when a resource has a blank label and fails validation' do
    before do
      create_resource(file_set_type: '3d', label: '3D 1', files: [['model.glb', glb, true]])
      create_resource(file_set_type: 'image', label: '', files: [['image1.jp2', MimeTypes::JP2, true]])
    end

    it 'names the resource without a label' do
      expect(result.errors).to eq(['Resource 2 has published files but is not a 3D or file resource.'])
    end
  end

  context 'when dark' do
    let(:dark) { true }

    before do
      create_resource(file_set_type: '3d', label: '3D 1', files: [['model.glb', glb, true]])
      create_resource(file_set_type: 'image', label: 'Image 1', files: [['image1.jp2', MimeTypes::JP2, true]])
    end

    it 'has warnings instead of errors' do
      expect(result).to have_attributes(
        errors: [], warnings: ['Resource 2 (Image 1) has published files but is not a 3D or file resource.']
      )
    end
  end

  context 'when there are no 3d resources' do
    before do
      create_resource(file_set_type: 'file', label: 'File 1', files: [['model.glb', glb, true]])
    end

    it 'has a warning but no errors' do
      expect(result).to have_attributes(errors: [], warnings: [not_exactly_one_model_warning])
    end
  end

  context 'when there is more than one 3d resource' do
    before do
      create_resource(file_set_type: '3d', label: '3D 1', files: [['model.glb', glb, true]])
      create_resource(file_set_type: '3d', label: '3D 2', files: [['model2.glb', glb, true]])
    end

    it 'has a warning but no errors' do
      expect(result).to have_attributes(errors: [], warnings: [not_exactly_one_model_warning])
    end
  end

  context 'when the 3d resource has more than one GLB file' do
    before do
      create_resource(file_set_type: '3d', label: '3D 1', files: [['model.glb', glb, true], ['model2.glb', glb, true]])
    end

    it 'has a warning but no errors' do
      expect(result).to have_attributes(errors: [], warnings: [not_exactly_one_model_warning])
    end
  end

  context 'when the 3d resource has no GLB file' do
    before do
      create_resource(file_set_type: '3d', label: '3D 1', files: [['model.obj', MimeTypes::OCTET_STREAM, true]])
    end

    it 'has a warning but no errors' do
      expect(result).to have_attributes(errors: [], warnings: [not_exactly_one_model_warning])
    end
  end
end
