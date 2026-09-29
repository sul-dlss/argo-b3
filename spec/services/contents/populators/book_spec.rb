# frozen_string_literal: true

require 'rails_helper'

# The grouping of files by basename is shared with the image populator and specified there.
RSpec.describe Contents::Populators::Book do
  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:cocina_object) do
    build(:dro_with_metadata, id: content.druid).new(access: { view: 'world', download: 'world' })
  end

  describe '.structure' do
    subject(:structure) { described_class.structure(content:, cocina_object:) }

    before do
      create(:content_file_binary, content:, filepath: 'aaa_notes.pdf', mime_type: 'application/pdf')
      create(:content_file_binary, content:, filepath: 'page_0001.tif', mime_type: 'image/tiff')
      create(:content_file_binary, content:, filepath: 'page_0002.tif', mime_type: 'image/tiff')
    end

    it 'types the file sets with images as pages, placing them before the file sets without images' do
      structure

      expect(content.content_file_sets.map { |file_set| [file_set.file_set_type, file_set.label] })
        .to eq([['page', 'Page 1'], ['page', 'Page 2'], ['object', 'Object 1']])
    end
  end

  describe '.append' do
    subject(:append) { described_class.append(content:, cocina_object:) }

    let(:existing_content_file_set) do
      create(:content_file_set, content:, file_set_type: 'page', label: 'Page 1', position: 1)
    end

    before do
      create(:content_file, content_file_set: existing_content_file_set,
                            content_file_binary: create(:content_file_binary, content:, filepath: 'page_0001.jp2',
                                                                              mime_type: 'image/jp2'),
                            label: 'page_0001.jp2')
      create(:content_file_binary, content:, filepath: 'page_0002.jp2', mime_type: 'image/jp2')
    end

    it 'creates a page file set at the end, continuing the label numbering' do
      append

      expect(content.content_file_sets.map { |file_set| [file_set.file_set_type, file_set.label] })
        .to eq([['page', 'Page 1'], ['page', 'Page 2']])
    end
  end
end
