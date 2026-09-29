# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::ContentFileBinaryDestroyer do
  subject(:call) { described_class.call(content_file_binaries: [content_file_binary]) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:content_file_binary) { create(:content_file_binary, content:, filepath: 'image1.tif') }
  let(:other_content_file_binary) { create(:content_file_binary, content:, filepath: 'image2.tif') }
  let(:content_file_set) { create(:content_file_set, content:, position: 1) }
  let(:other_content_file_set) { create(:content_file_set, content:, position: 2) }
  let!(:content_file) { create(:content_file, content_file_set:, content_file_binary:) }

  context 'when the binary is the only file in its resource' do
    it 'deletes the binary, its file, and the resource' do
      call

      expect(ContentFileBinary.exists?(content_file_binary.id)).to be false
      expect(ContentFile.exists?(content_file.id)).to be false
      expect(ContentFileSet.exists?(content_file_set.id)).to be false
    end
  end

  context 'when the binary is referenced by files in multiple resources' do
    let!(:shared_content_file) do
      create(:content_file, content_file_set: other_content_file_set, content_file_binary:, position: 1)
    end
    let!(:remaining_content_file) do
      create(:content_file, content_file_set: other_content_file_set, content_file_binary: other_content_file_binary,
                            position: 2)
    end

    it 'deletes every file referencing the binary and only the emptied resources' do
      call

      expect(ContentFile.exists?(content_file.id)).to be false
      expect(ContentFile.exists?(shared_content_file.id)).to be false
      expect(ContentFileSet.exists?(content_file_set.id)).to be false
      expect(ContentFileSet.exists?(other_content_file_set.id)).to be true
      expect(ContentFile.exists?(remaining_content_file.id)).to be true
      expect(ContentFileBinary.exists?(other_content_file_binary.id)).to be true
    end
  end

  context 'when another resource has no files' do
    before do
      other_content_file_set
    end

    it 'does not delete that resource' do
      call

      expect(ContentFileSet.exists?(other_content_file_set.id)).to be true
    end
  end

  context 'when the binary has been staged' do
    let(:staging_filepath) do
      StagingSupport.staging_filepath(druid: content.druid, filepath: content_file_binary.filepath)
    end

    before do
      content_file_binary.update!(file_location: 'stage')
      FileUtils.mkdir_p(File.dirname(staging_filepath))
      FileUtils.touch(staging_filepath)
    end

    after do
      FileUtils.rm_f(staging_filepath)
    end

    it 'deletes the staged file' do
      call

      expect(File.exist?(staging_filepath)).to be false
    end

    context 'when the enclosing transaction is rolled back' do
      it 'does not delete the staged file' do
        ActiveRecord::Base.transaction do
          call
          raise ActiveRecord::Rollback
        end

        expect(File.exist?(staging_filepath)).to be true
        expect(ContentFileBinary.exists?(content_file_binary.id)).to be true
      end
    end
  end
end
