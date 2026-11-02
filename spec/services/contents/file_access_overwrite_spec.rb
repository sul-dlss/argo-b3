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
        .to eq(view: 'dark', download: 'none', location: nil, preserve: true, shelve: false, publish: false)
    end

    it 'applies them to a cocina file' do
      file_props = { access: { view: 'world', download: 'world' },
                     administrative: { publish: true, sdrPreserve: false, shelve: true } }

      file_access_overwrite.apply_to_cocina_file!(file_props)

      expect(file_props).to eq(access: { view: 'dark', download: 'none' },
                               administrative: { publish: false, sdrPreserve: true, shelve: false })
    end
  end

  context 'when changed to citation-only' do
    let(:access) { { view: 'citation-only', download: 'none', location: nil } }

    it 'applies dark access, without changing whether the files are shelved or published' do
      file_props = { access: { view: 'world', download: 'world' },
                     administrative: { publish: true, sdrPreserve: true, shelve: true } }

      file_access_overwrite.apply_to_cocina_file!(file_props)

      expect(file_access_overwrite.content_file_attributes).to eq(view: 'dark', download: 'none', location: nil)
      expect(file_props).to eq(access: { view: 'dark', download: 'none' },
                               administrative: { publish: true, sdrPreserve: true, shelve: true })
    end
  end
end
