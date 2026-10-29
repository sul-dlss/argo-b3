# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ManifestCsv::Validator do
  subject(:validator) { described_class.new(csv:, files_path:) }

  let(:files_path) { '/dor/staging/deposit' }
  let(:csv) do
    <<~CSV
      druid,folder_name
      druid:bc123df4567,folder1
      druid:cd234fg5678,nested/folder2
    CSV
  end

  it 'is valid' do
    expect(validator).to be_valid
    expect(validator.errors).to be_empty
  end

  context 'when columns are missing' do
    let(:csv) { "druid,filename\ndruid:bc123df4567,\n" }

    it 'reports only the missing columns' do
      expect(validator).not_to be_valid
      expect(validator.errors).to eq(['Missing columns: folder_name.'])
    end
  end

  context 'when there are no rows' do
    let(:csv) { "druid,folder_name\n" }

    it 'reports only the missing rows' do
      expect(validator).not_to be_valid
      expect(validator.errors).to eq(['No rows.'])
    end
  end

  context 'when cells are blank' do
    let(:csv) do
      <<~CSV
        druid,folder_name
        ,folder1
        druid:cd234fg5678,
      CSV
    end

    it 'reports the rows' do
      expect(validator).not_to be_valid
      expect(validator.errors).to eq(['Blank druid in rows: 2.', 'Blank folder_name in rows: 3.'])
    end
  end

  context 'when a druid is duplicated' do
    let(:csv) do
      <<~CSV
        druid,folder_name
        druid:bc123df4567,folder1
        druid:bc123df4567,folder2
      CSV
    end

    it 'reports the druid' do
      expect(validator).not_to be_valid
      expect(validator.errors).to eq(['Duplicate druids: druid:bc123df4567.'])
    end
  end

  context 'when a folder is used by more than one druid' do
    let(:csv) do
      <<~CSV
        druid,folder_name
        druid:bc123df4567,folder1
        druid:cd234fg5678,folder1
      CSV
    end

    it 'reports the folder' do
      expect(validator).not_to be_valid
      expect(validator.errors).to eq(['Folders used by more than one druid: folder1.'])
    end
  end

  context 'when folders are outside the files path' do
    let(:csv) do
      <<~CSV
        druid,folder_name
        druid:bc123df4567,../../etc
        druid:cd234fg5678,/etc
        druid:df345gh6789,.
        druid:fg456hj7890,folder1/../../other
      CSV
    end

    it 'reports the folders' do
      expect(validator).not_to be_valid
      expect(validator.errors).to eq(['Folders outside the file location: ../../etc, /etc, ., folder1/../../other.'])
    end
  end

  context 'when there is no files path' do
    let(:files_path) { nil }
    let(:csv) { "druid,folder_name\ndruid:bc123df4567,../../etc\n" }

    it 'does not check the folders' do
      expect(validator).to be_valid
    end
  end
end
