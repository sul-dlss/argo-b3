# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentFileBinary do
  describe '#filename' do
    subject(:content_file_binary) { build(:content_file_binary, filepath: 'folder1/folder2/image1.tif') }

    it 'returns the filename portion of the filepath' do
      expect(content_file_binary.filename).to eq('image1.tif')
    end
  end

  describe '#set_filepath_parts' do
    subject(:content_file_binary) { create(:content_file_binary, filepath: 'folder1/folder2/image1.tif') }

    it 'derives path_parts, basename, and extname from the filepath' do
      expect(content_file_binary.path_parts).to eq(%w[folder1 folder2])
      expect(content_file_binary.basename).to eq('image1')
      expect(content_file_binary.extname).to eq('tif')
    end
  end

  describe 'deposit validation context' do
    let(:deposit_ready_attributes) do
      {
        size: 12_345,
        md5_digest: 'b6ce12a1dd5db09f10b51659c83f90a3',
        sha1_digest: 'ff66b3b3dc3ef733d39e949549791ff78754871b',
        mime_type: 'image/tiff',
        file_location: 'deposited'
      }
    end

    it 'is valid when required attributes are present and file_location is deposited or stage' do
      expect(build(:content_file_binary, **deposit_ready_attributes)).to be_valid(:deposit)
      expect(build(:content_file_binary, **deposit_ready_attributes, file_location: 'stage')).to be_valid(:deposit)
    end

    it 'is invalid without size, md5_digest, sha1_digest, or mime_type' do
      content_file_binary = build(:content_file_binary, **deposit_ready_attributes,
                                                         size: nil, md5_digest: nil, sha1_digest: nil, mime_type: nil)

      expect(content_file_binary).not_to be_valid(:deposit)
      expect(content_file_binary.errors[:size]).to include("can't be blank")
      expect(content_file_binary.errors[:md5_digest]).to include("can't be blank")
      expect(content_file_binary.errors[:sha1_digest]).to include("can't be blank")
      expect(content_file_binary.errors[:mime_type]).to include("can't be blank")
    end

    it 'is invalid when file_location is not deposited or stage' do
      content_file_binary = build(:content_file_binary, **deposit_ready_attributes, file_location: 'attached')

      expect(content_file_binary).not_to be_valid(:deposit)
      expect(content_file_binary.errors[:file_location]).to include('is not included in the list')
    end
  end
end
