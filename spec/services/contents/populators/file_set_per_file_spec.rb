# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Populators::FileSetPerFile do
  subject(:structure) { described_class.structure(content:, cocina_object:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:cocina_object) { build(:dro_with_metadata, id: content.druid) }
  let!(:content_file_binary) { create(:content_file_binary, content:, filepath: 'folder/image1.tif') }

  describe '.structure' do
    it 'creates a file set and file for an unassociated binary' do
      structure

      content_file_set = content.content_file_sets.sole
      expect(content_file_set).to have_attributes(file_set_type: 'object', label: '')

      content_file = content_file_set.content_files.sole
      expect(content_file).to have_attributes(label: '', preserve: true, publish: true, shelve: true,
                                              view: cocina_object.access.view,
                                              download: cocina_object.access.download,
                                              location: cocina_object.access.location)
      expect(content_file.content_file_binary).to eq(content_file_binary)
    end

    context 'when there are multiple unassociated binaries' do
      let!(:other_content_file_binary) { create(:content_file_binary, content:, filepath: 'folder/image10.tif') }
      let!(:another_content_file_binary) { create(:content_file_binary, content:, filepath: 'folder/image0.tif') }

      it 'creates a file set per binary, in path order' do
        structure

        expect(content.content_file_sets.map { |file_set| file_set.content_files.sole.content_file_binary })
          .to eq([another_content_file_binary, content_file_binary, other_content_file_binary])
        expect(content.content_file_sets.pluck(:position)).to eq([1, 2, 3])
      end
    end

    context 'when a binary is already associated with a file' do
      let(:content_file_set) { create(:content_file_set, content:) }

      before do
        create(:content_file, content_file_set:, content_file_binary:)
      end

      it 'does not create another file set for it' do
        expect { structure }.not_to change(ContentFileSet, :count)
        expect(content.content_files.sole.content_file_binary).to eq(content_file_binary)
      end
    end

    context 'when the object is embargoed' do
      let(:cocina_object) do
        build(:dro_with_metadata, id: content.druid).new(
          access: {
            view: 'citation-only',
            download: 'none',
            embargo: {
              releaseDate: DateTime.parse('2040-06-15T19:00:00Z'),
              view: 'stanford',
              download: 'stanford'
            }
          }
        )
      end

      it 'uses the embargo access settings' do
        structure

        expect(content.content_files.sole).to have_attributes(view: 'stanford', download: 'stanford')
      end
    end

    context 'when the object has citation-only access' do
      let(:cocina_object) do
        build(:dro_with_metadata, id: content.druid).new(access: { view: 'citation-only', download: 'none' })
      end

      it 'maps citation-only view access to dark' do
        structure

        expect(content.content_files.sole).to have_attributes(view: 'dark', download: 'none')
      end
    end
  end

  describe '.append' do
    subject(:append) { described_class.append(content:, cocina_object:) }

    let(:existing_content_file_set) { create(:content_file_set, content:) }
    let!(:existing_content_file) do
      create(:content_file, content_file_set: existing_content_file_set, content_file_binary:)
    end
    let!(:unassociated_content_file_binary) { create(:content_file_binary, content:, filepath: 'folder/image2.tif') }

    it 'adds a file set for the unassociated binary at the end of the existing file sets' do
      append

      expect(content.content_file_sets.pluck(:position)).to eq([1, 2])

      appended_content_file_set = content.content_file_sets.last
      expect(appended_content_file_set.content_files.sole.content_file_binary)
        .to eq(unassociated_content_file_binary)
    end

    it 'retains the existing file set and file' do
      append

      expect(existing_content_file_set.reload).to have_attributes(position: 1)
      expect(existing_content_file_set.content_files.sole).to eq(existing_content_file)
    end
  end
end
