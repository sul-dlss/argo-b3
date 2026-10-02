# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Populators::FileType do
  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:cocina_object) do
    build(:dro_with_metadata, id: content.druid).new(access: { view: 'world', download: 'world' })
  end
  let!(:content_file_binary) { create(:content_file_binary, content:, filepath: 'folder/file1.txt') }

  describe '.structure' do
    subject(:structure) { described_class.structure(content:, cocina_object:) }

    let!(:other_content_file_binary) { create(:content_file_binary, content:, filepath: 'folder/file0.txt') }

    it 'creates a file file set per binary, in path order' do
      structure

      expect(content.content_file_sets.map { |file_set| [file_set.file_set_type, file_set.label] })
        .to eq([['file', ''], ['file', '']])
      expect(content.content_file_sets.map { |file_set| file_set.content_files.sole.content_file_binary })
        .to eq([other_content_file_binary, content_file_binary])
    end
  end

  describe '.append' do
    subject(:append) { described_class.append(content:, cocina_object:) }

    let(:existing_content_file_set) { create(:content_file_set, content:, file_set_type: 'file') }
    let!(:unassociated_content_file_binary) { create(:content_file_binary, content:, filepath: 'folder/file2.txt') }

    before do
      create(:content_file, content_file_set: existing_content_file_set, content_file_binary:)
    end

    it 'adds a file file set for the unassociated binary at the end of the existing file sets' do
      append

      appended_content_file_set = content.content_file_sets.last
      expect(appended_content_file_set).to have_attributes(file_set_type: 'file', position: 2)
      expect(appended_content_file_set.content_files.sole.content_file_binary)
        .to eq(unassociated_content_file_binary)
    end
  end
end
