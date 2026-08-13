# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentFile do
  describe '#filename' do
    subject(:content_file) { build(:content_file, filepath: 'folder1/folder2/image1.tif') }

    it 'returns the filename portion of the filepath' do
      expect(content_file.filename).to eq('image1.tif')
    end
  end

  describe '#set_filepath_parts' do
    subject(:content_file) { create(:content_file, filepath: 'folder1/folder2/image1.tif') }

    it 'derives path_parts, basename, and extname from the filepath' do
      expect(content_file.path_parts).to eq(%w[folder1 folder2])
      expect(content_file.basename).to eq('image1')
      expect(content_file.extname).to eq('tif')
    end
  end

  describe 'deposit validation context' do
    let(:deposit_ready_attributes) do
      {
        external_identifier: 'https://cocina.sul.stanford.edu/file/abc',
        mime_type: 'image/tiff',
        size: 12_345,
        md5_digest: 'b6ce12a1dd5db09f10b51659c83f90a3',
        sha1_digest: 'ff66b3b3dc3ef733d39e949549791ff78754871b',
        file_location: 'deposited'
      }
    end

    it 'is valid when required attributes are present and file_location is deposited or stage' do
      expect(build(:content_file, **deposit_ready_attributes)).to be_valid(:deposit)
      expect(build(:content_file, **deposit_ready_attributes, file_location: 'stage')).to be_valid(:deposit)
    end

    it 'is invalid without external_identifier, mime_type, size, md5_digest, or sha1_digest' do
      content_file = build(:content_file, **deposit_ready_attributes,
                                          external_identifier: nil, mime_type: nil, size: nil,
                                          md5_digest: nil, sha1_digest: nil)

      expect(content_file).not_to be_valid(:deposit)
      expect(content_file.errors[:external_identifier]).to include("can't be blank")
      expect(content_file.errors[:mime_type]).to include("can't be blank")
      expect(content_file.errors[:size]).to include("can't be blank")
      expect(content_file.errors[:md5_digest]).to include("can't be blank")
      expect(content_file.errors[:sha1_digest]).to include("can't be blank")
    end

    it 'is invalid when file_location is not deposited or stage' do
      content_file = build(:content_file, **deposit_ready_attributes, file_location: 'attached')

      expect(content_file).not_to be_valid(:deposit)
      expect(content_file.errors[:file_location]).to include('is not included in the list')
    end
  end
end
