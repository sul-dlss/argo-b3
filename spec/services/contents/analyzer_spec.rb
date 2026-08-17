# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Analyzer do
  subject(:call) { described_class.call(content_file_binary:) }

  describe '#call' do
    context 'when the digests and mime type are not yet set' do
      let(:content_file_binary) { create(:content_file_binary, file_location: 'attached') }

      before do
        content_file_binary.file.attach(fixture_file_upload('dropzone_upload.txt', 'text/plain'))
      end

      it 'computes and persists the digests, mime type, and size' do
        filepath_on_disk = content_file_binary.filepath_on_disk

        call

        expect(content_file_binary.reload).to have_attributes(
          md5_digest: Digest::MD5.file(filepath_on_disk).hexdigest,
          sha1_digest: Digest::SHA1.file(filepath_on_disk).hexdigest,
          mime_type: 'text/plain',
          size: File.size(filepath_on_disk)
        )
      end
    end

    context 'when the digests are already set' do
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'attached', md5_digest: 'existing-md5',
                                     sha1_digest: 'existing-sha1', mime_type: 'text/plain', size: 1)
      end

      it 'does not recompute the digests' do
        call

        expect(content_file_binary).to have_attributes(md5_digest: 'existing-md5', sha1_digest: 'existing-sha1')
      end
    end

    context 'when only one digest is set' do
      let(:content_file_binary) { create(:content_file_binary, file_location: 'attached', md5_digest: 'stale-md5') }

      before do
        content_file_binary.file.attach(fixture_file_upload('dropzone_upload.txt', 'text/plain'))
      end

      it 'recomputes both digests from the file' do
        filepath_on_disk = content_file_binary.filepath_on_disk

        call

        expect(content_file_binary).to have_attributes(
          md5_digest: Digest::MD5.file(filepath_on_disk).hexdigest,
          sha1_digest: Digest::SHA1.file(filepath_on_disk).hexdigest
        )
      end
    end

    context 'when the mime type is already set' do
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'attached', md5_digest: 'existing-md5',
                                     sha1_digest: 'existing-sha1', mime_type: 'existing-mime-type', size: 1)
      end

      it 'does not recompute the mime type' do
        call

        expect(content_file_binary.mime_type).to eq('existing-mime-type')
      end
    end

    context 'when the file location is attached' do
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'attached', md5_digest: 'existing-md5',
                                     sha1_digest: 'existing-sha1')
      end

      before do
        # identify: false keeps the declared content type instead of letting ActiveStorage sniff it,
        # so this test can prove the blob's content type (not the file contents) drives the result.
        content_file_binary.file.attach(
          io: Rails.root.join('spec/fixtures/files/dropzone_upload.txt').open,
          filename: 'dropzone_upload.txt',
          content_type: 'application/octet-stream',
          identify: false
        )
      end

      it "uses the attached blob's content type" do
        call

        expect(content_file_binary.mime_type).to eq('application/octet-stream')
      end
    end

    context 'when the file location is not attached' do
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'deposited', md5_digest: 'existing-md5',
                                     sha1_digest: 'existing-sha1')
      end

      before do
        content_file_binary.file.attach(
          io: Rails.root.join('spec/fixtures/files/catalog_record_id_and_barcode.xlsx').open,
          filename: 'catalog_record_id_and_barcode.xlsx',
          content_type: 'application/octet-stream',
          identify: false
        )
      end

      it 'sniffs the mime type from the file contents on disk instead of using the (unset) blob content type' do
        call

        expect(content_file_binary.mime_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end
    end

    context 'when the size is not yet set' do
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'attached', md5_digest: 'existing-md5',
                                     sha1_digest: 'existing-sha1', mime_type: 'text/plain')
      end

      before do
        content_file_binary.file.attach(fixture_file_upload('dropzone_upload.txt', 'text/plain'))
      end

      it "uses the attached blob's byte size" do
        call

        expect(content_file_binary.size).to eq(content_file_binary.file.blob.byte_size)
      end
    end

    context 'when the size is already set' do
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'attached', md5_digest: 'existing-md5',
                                     sha1_digest: 'existing-sha1', mime_type: 'text/plain', size: 12_345)
      end

      before do
        content_file_binary.file.attach(fixture_file_upload('dropzone_upload.txt', 'text/plain'))
      end

      it 'does not recompute the size' do
        call

        expect(content_file_binary.size).to eq(12_345)
      end
    end

    context 'when the file location is not attached and the size is not yet set' do
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'deposited', md5_digest: 'existing-md5',
                                     sha1_digest: 'existing-sha1', mime_type: 'text/plain')
      end

      before do
        content_file_binary.file.attach(
          io: Rails.root.join('spec/fixtures/files/catalog_record_id_and_barcode.xlsx').open,
          filename: 'catalog_record_id_and_barcode.xlsx',
          content_type: 'application/octet-stream',
          identify: false
        )
      end

      it 'reads the size from the file on disk instead of using the blob byte size' do
        filepath_on_disk = content_file_binary.filepath_on_disk

        call

        expect(content_file_binary.size).to eq(File.size(filepath_on_disk))
      end
    end
  end
end
