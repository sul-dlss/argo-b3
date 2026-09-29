# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Populators::Geo do
  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:cocina_object) do
    build(:dro_with_metadata, id: content.druid).new(access: { view: 'world', download: 'world' })
  end

  describe '.structure' do
    subject(:structure) { described_class.structure(content:, cocina_object:) }

    context 'when there are multiple files' do
      let!(:json_binary) do
        create(:content_file_binary, content:, filepath: 'data/index_map.json', mime_type: 'application/json')
      end
      let!(:tiff_binary) do
        create(:content_file_binary, content:, filepath: 'data/map.tif', mime_type: 'image/tiff')
      end
      let!(:zip_binary) do
        create(:content_file_binary, content:, filepath: 'data.zip', mime_type: 'application/zip')
      end

      it 'creates a single object file set' do
        structure

        expect(content.content_file_sets.sole).to have_attributes(file_set_type: 'object', label: '')
      end

      it 'creates a file per binary in path order with attributes for its mime type' do
        structure

        content_files = content.content_file_sets.sole.content_files
        expect(content_files.map(&:content_file_binary)).to eq([zip_binary, json_binary, tiff_binary])
        expect(content_files.first).to have_attributes(label: 'data.zip', preserve: true, shelve: false,
                                                       publish: false, use: nil,
                                                       view: cocina_object.access.view,
                                                       download: cocina_object.access.download,
                                                       location: cocina_object.access.location)
        expect(content_files.second).to have_attributes(label: 'data/index_map.json', preserve: true, shelve: true,
                                                        publish: true)
        expect(content_files.third).to have_attributes(label: 'data/map.tif', preserve: true, shelve: false,
                                                       publish: false)
      end
    end

    context 'when the object is dark' do
      let(:cocina_object) do
        build(:dro_with_metadata, id: content.druid).new(access: { view: 'dark', download: 'none' })
      end

      before do
        create(:content_file_binary, content:, filepath: 'index_map.json', mime_type: 'application/json')
      end

      it 'preserves but does not shelve or publish the files' do
        structure

        expect(content.content_files.sole)
          .to have_attributes(preserve: true, shelve: false, publish: false, view: 'dark')
      end
    end
  end

  describe '.append' do
    subject(:append) { described_class.append(content:, cocina_object:) }

    before do
      create(:content_file_binary, content:, filepath: 'data.zip', mime_type: 'application/zip')
    end

    context 'when there is an existing file set' do
      let!(:existing_content_file_set) do
        create(:content_file_set, content:, file_set_type: 'object', label: 'Edited label', position: 1)
      end

      before do
        create(:content_file, content_file_set: existing_content_file_set,
                              content_file_binary: create(:content_file_binary, content:, filepath: 'index_map.json',
                                                                                mime_type: 'application/json'),
                              label: 'index_map.json')
      end

      it 'adds the files to the existing file set without changing the file set' do
        append

        expect(content.content_file_sets.sole).to have_attributes(file_set_type: 'object', label: 'Edited label')
        expect(existing_content_file_set.content_files.map(&:label)).to eq(%w[index_map.json data.zip])
      end
    end

    context 'when there are no existing file sets' do
      it 'creates a single object file set' do
        append

        expect(content.content_file_sets.sole).to have_attributes(file_set_type: 'object', label: '')
        expect(content.content_files.sole).to have_attributes(label: 'data.zip')
      end
    end
  end
end
