# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Populators::ThreeDimensional do
  subject(:structure) { described_class.structure(content:, cocina_object:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:cocina_object) do
    build(:dro_with_metadata, id: content.druid).new(access: { view: 'world', download: 'world' })
  end

  describe '.disqualifying_reasons' do
    subject(:reasons) { described_class.disqualifying_reasons(content:, cocina_object:) }

    context 'when there is a model' do
      before do
        create(:content_file_binary, content:, filepath: 'folder/model.glb', mime_type: 'model/gltf-binary')
        create(:content_file_binary, content:, filepath: 'notes.txt', mime_type: 'text/plain')
      end

      it 'has no reasons' do
        expect(reasons).to eq([])
      end
    end

    context 'when there are no models' do
      before do
        create(:content_file_binary, content:, filepath: 'notes.txt', mime_type: 'text/plain')
      end

      it 'has the no models reason' do
        expect(reasons).to eq([:no_models])
      end
    end
  end

  describe '.structure' do
    context 'when there is a model' do
      let!(:model_binary) do
        create(:content_file_binary, content:, filepath: 'model.glb', mime_type: 'model/gltf-binary')
      end

      it 'creates a 3d file set with a file for the model' do
        structure

        expect(content.content_file_sets.sole).to have_attributes(file_set_type: '3d', label: '')
        content_file = content.content_files.sole
        expect(content_file.content_file_binary).to eq(model_binary)
        expect(content_file).to have_attributes(label: 'model.glb', preserve: true, shelve: true, publish: true,
                                                use: nil,
                                                view: cocina_object.access.view,
                                                download: cocina_object.access.download,
                                                location: cocina_object.access.location)
      end
    end

    context 'when there are models and other files' do
      before do
        # Sorts before the first model by path, but is placed after it because it is not the first model.
        create(:content_file_binary, content:, filepath: 'aaa_notes.txt', mime_type: 'text/plain')
        create(:content_file_binary, content:, filepath: 'model10.glb', mime_type: 'model/gltf-binary')
        create(:content_file_binary, content:, filepath: 'model2.glb', mime_type: 'model/gltf-binary')
        create(:content_file_binary, content:, filepath: 'image.tif', mime_type: 'image/tiff')
      end

      it 'creates a 3d file set for the first model, followed by a file file set per other file in path order' do
        structure

        expect(content.content_file_sets.map { |file_set| [file_set.file_set_type, file_set.label] })
          .to eq([['3d', ''], ['file', 'File 1'], ['file', 'File 2'], ['file', 'File 3']])
        expect(content.content_file_sets.pluck(:position)).to eq([1, 2, 3, 4])
        expect(content.content_files.map(&:filepath)).to eq(%w[model2.glb aaa_notes.txt image.tif model10.glb])
      end

      it 'uses the attributes for the mime type of each file' do
        structure

        expect(content.content_files.find_by(label: 'image.tif'))
          .to have_attributes(preserve: true, shelve: false, publish: false)
      end
    end

    context 'when the object is dark' do
      let(:cocina_object) do
        build(:dro_with_metadata, id: content.druid).new(access: { view: 'dark', download: 'none' })
      end

      before do
        create(:content_file_binary, content:, filepath: 'model.glb', mime_type: 'model/gltf-binary')
      end

      it 'preserves but does not shelve or publish the files' do
        structure

        expect(content.content_files.sole).to have_attributes(preserve: true, shelve: false, publish: false,
                                                              view: 'dark')
      end
    end
  end

  describe '.append' do
    subject(:append) { described_class.append(content:, cocina_object:) }

    let(:existing_three_dimensional_file_set) do
      create(:content_file_set, content:, file_set_type: '3d', label: '', position: 1)
    end
    let(:existing_file_file_set) do
      create(:content_file_set, content:, file_set_type: 'file', label: 'File 1', position: 2)
    end
    let!(:existing_content_file) do
      create(:content_file, content_file_set: existing_three_dimensional_file_set,
                            content_file_binary: create(:content_file_binary, content:, filepath: 'model1.glb',
                                                                              mime_type: 'model/gltf-binary'),
                            label: 'model1.glb')
    end

    before do
      create(:content_file, content_file_set: existing_file_file_set,
                            content_file_binary: create(:content_file_binary, content:, filepath: 'notes1.txt',
                                                                              mime_type: 'text/plain'),
                            label: 'notes1.txt')
      create(:content_file_binary, content:, filepath: 'notes2.txt', mime_type: 'text/plain')
      create(:content_file_binary, content:, filepath: 'model2.glb', mime_type: 'model/gltf-binary')
    end

    it 'creates file file sets at the end in path order, including for models, continuing the label numbering' do
      append

      expect(content.content_file_sets.map { |file_set| [file_set.file_set_type, file_set.label] })
        .to eq([['3d', ''], ['file', 'File 1'], ['file', 'File 2'], ['file', 'File 3']])
      expect(content.content_file_sets.pluck(:position)).to eq([1, 2, 3, 4])
      expect(content.content_files.map(&:filepath)).to eq(%w[model1.glb notes1.txt model2.glb notes2.txt])
    end

    it 'retains the existing file sets and files' do
      append

      expect(existing_three_dimensional_file_set.reload).to have_attributes(position: 1)
      expect(existing_three_dimensional_file_set.content_files.sole).to eq(existing_content_file)
    end
  end
end
