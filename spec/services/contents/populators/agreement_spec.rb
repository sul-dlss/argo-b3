# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Populators::Agreement do
  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:cocina_object) { build(:agreement_with_metadata, id: content.druid) }
  let!(:content_file_binary) do
    create(:content_file_binary, content:, filepath: 'folder/file1.pdf', mime_type: 'application/pdf')
  end

  describe '.structure' do
    subject(:structure) { described_class.structure(content:, cocina_object:) }

    let!(:other_content_file_binary) do
      create(:content_file_binary, content:, filepath: 'folder/file0.pdf', mime_type: 'application/pdf')
    end

    it 'creates an unlabeled file file set per binary, in path order' do
      structure

      expect(content.content_file_sets.map { |file_set| [file_set.file_set_type, file_set.label] })
        .to eq([['file', ''], ['file', '']])
      expect(content.content_file_sets.map { |file_set| file_set.content_files.sole.content_file_binary })
        .to eq([other_content_file_binary, content_file_binary])
    end

    it 'creates dark, preserved, unpublished files without a role' do
      structure

      expect(content.content_file_sets.first.content_files.sole).to have_attributes(
        label: '', preserve: true, publish: false, shelve: false, use: nil,
        view: 'dark', download: 'none', location: nil
      )
    end
  end

  describe '.append' do
    subject(:append) { described_class.append(content:, cocina_object:) }

    let(:existing_content_file_set) { create(:content_file_set, content:, file_set_type: 'file', label: '') }
    let!(:unassociated_content_file_binary) { create(:content_file_binary, content:, filepath: 'folder/file2.pdf') }

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
