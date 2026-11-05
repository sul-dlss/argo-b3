# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::FileAccessOverwrite do
  subject(:file_access_overwrite) { described_class.new(previous_access:, access:, overwrite:) }

  let(:previous_access) { Cocina::Models::DROAccess.new(view: 'world', download: 'world') }
  let(:overwrite) { true }

  context 'when the access changed' do
    let(:access) { { view: 'location-based', download: 'location-based', location: 'spec' } }

    it 'applies the access to the files' do
      expect(file_access_overwrite.apply?).to be true
      expect(file_access_overwrite.content_file_attributes)
        .to eq(view: 'location-based', download: 'location-based', location: 'spec')
    end
  end

  context 'when the access changed without overwriting' do
    let(:access) { { view: 'stanford', download: 'stanford', location: nil } }
    let(:overwrite) { false }

    it 'does not apply the access' do
      expect(file_access_overwrite.apply?).to be false
    end
  end

  context 'when the access did not change' do
    # A blank location is the same as none.
    let(:access) { { view: 'world', download: 'world', location: '' } }

    it 'does not apply the access' do
      expect(file_access_overwrite.apply?).to be false
    end
  end

  context 'when dark' do
    let(:previous_access) { Cocina::Models::DROAccess.new(view: 'dark', download: 'none') }
    let(:access) { { view: 'dark', download: 'none', location: nil } }
    let(:overwrite) { false }

    it 'applies dark access and unshelves and unpublishes the files, even if unchanged and not overwriting' do
      expect(file_access_overwrite.apply?).to be true
      expect(file_access_overwrite.content_file_attributes)
        .to eq(view: 'dark', download: 'none', location: nil, shelve: false, publish: false)
    end

    it 'applies them to the cocina files, removing those no longer preserved, shelved, or published' do
      structural_props = { contains: [
        file_set_props(cocina_file_props('image.tif', sdr_preserve: true), cocina_file_props('image.jp2')),
        file_set_props(cocina_file_props('other.jp2')),
        file_set_props
      ] }

      file_access_overwrite.apply_to_cocina_structural!(structural_props)

      # The file set emptied by removing its file is removed, but not one that was already empty.
      expect(structural_props[:contains].map { |props| props[:structural][:contains] }).to eq(
        [[{ filename: 'image.tif', access: { view: 'dark', download: 'none' },
            administrative: { publish: false, sdrPreserve: true, shelve: false } }],
         []]
      )
    end

    describe '#apply_to_content!' do
      let(:content) { create(:content, :mutable) }
      let(:content_file_set) { create(:content_file_set, content:) }
      let(:other_content_file_set) { create(:content_file_set, content:, position: 2) }
      let!(:preserved_content_file) { create(:content_file, content_file_set:) }
      let!(:derivative_content_file) do
        create(:content_file, content_file_set:, position: 2, preserve: false,
                              content_file_binary: create(:content_file_binary, content:, filepath: 'image1.jp2'))
      end

      before do
        create(:content_file, content_file_set: other_content_file_set, preserve: false,
                              content_file_binary: create(:content_file_binary, content:, filepath: 'image2.jp2'))
      end

      it 'removes the content files no longer preserved, shelved, or published, and the resources they empty' do
        file_access_overwrite.apply_to_content!(content)

        expect(preserved_content_file.reload).to have_attributes(view: 'dark', download: 'none', preserve: true,
                                                                 shelve: false, publish: false)
        expect(ContentFile.exists?(derivative_content_file.id)).to be false
        expect(ContentFileBinary.exists?(derivative_content_file.content_file_binary_id)).to be false
        expect(content.content_file_sets.reload).to eq([content_file_set])
      end
    end
  end

  context 'when changed to citation-only' do
    let(:access) { { view: 'citation-only', download: 'none', location: nil } }

    it 'applies dark access, without changing whether the files are shelved or published, or removing them' do
      structural_props = { contains: [file_set_props(cocina_file_props('image.jp2', shelve: true, publish: true))] }

      file_access_overwrite.apply_to_cocina_structural!(structural_props)

      expect(file_access_overwrite.content_file_attributes).to eq(view: 'dark', download: 'none', location: nil)
      expect(structural_props[:contains].sole[:structural][:contains]).to eq(
        [{ filename: 'image.jp2', access: { view: 'dark', download: 'none' },
           administrative: { publish: true, sdrPreserve: false, shelve: true } }]
      )
    end
  end

  def file_set_props(*files_props)
    { structural: { contains: files_props } }
  end

  def cocina_file_props(filename, sdr_preserve: false, shelve: true, publish: true)
    { filename:, access: { view: 'world', download: 'world' },
      administrative: { publish:, sdrPreserve: sdr_preserve, shelve: } }
  end
end
