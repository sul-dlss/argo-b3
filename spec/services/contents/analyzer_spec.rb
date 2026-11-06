# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Analyzer do
  subject(:call) { described_class.call(content_file_binary:, mime_type_only:) }

  let(:mime_type_only) { false }

  describe '#call' do
    context 'when the digests and mime type are not yet set' do
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'attached', filepath: 'dropzone_upload.txt')
      end

      before do
        content_file_binary.file.attach(fixture_file_upload('dropzone_upload.txt', 'text/plain'))
      end

      it 'computes and persists the digests, mime type, and size' do
        call

        expect(content_file_binary.reload).to have_attributes(
          md5_digest: '9d30b5a5e132b233e2626b791d6ec6d0',
          sha1_digest: '2e465fe62e5d67b6da4c7220698ddaf51759d5ec',
          mime_type: 'text/plain',
          size: 52
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
        call

        expect(content_file_binary).to have_attributes(
          md5_digest: '9d30b5a5e132b233e2626b791d6ec6d0',
          sha1_digest: '2e465fe62e5d67b6da4c7220698ddaf51759d5ec'
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

    context 'when the file location is attached and the browser declared a different type' do
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'attached', filepath: 'catalog_record_id_and_barcode.csv',
                                     md5_digest: 'existing-md5', sha1_digest: 'existing-sha1')
      end

      before do
        content_file_binary.file.attach(
          fixture_file_upload('catalog_record_id_and_barcode.csv', 'application/vnd.ms-excel')
        )
      end

      it 'determines the mime type from the file contents and filepath' do
        call

        expect(content_file_binary.mime_type).to eq('text/csv')
      end
    end

    context 'when the file is on a mount' do
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'mount', mount_path: file_fixture_path,
                                     filepath: 'catalog_record_id_and_barcode.xlsx',
                                     md5_digest: 'existing-md5', sha1_digest: 'existing-sha1')
      end

      it 'sniffs the mime type from the file contents on disk' do
        call

        expect(content_file_binary.mime_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      end
    end

    context 'when the file on a mount is a GLB model' do
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'mount', mount_path: file_fixture_path, filepath: 'model.glb',
                                     md5_digest: 'existing-md5', sha1_digest: 'existing-sha1')
      end

      it 'sniffs the model mime type' do
        call

        expect(content_file_binary.mime_type).to eq('model/gltf-binary')
      end
    end

    context 'when the file on a mount is a FlatGeobuf' do
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'mount', mount_path: file_fixture_path, filepath: 'index_map.fgb',
                                     md5_digest: 'existing-md5', sha1_digest: 'existing-sha1')
      end

      it 'sniffs the FlatGeobuf mime type' do
        call

        expect(content_file_binary.mime_type).to eq('application/vnd.fgb')
      end
    end

    context 'when the file on a mount is a PMTiles archive' do
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'mount', mount_path: file_fixture_path,
                                     filepath: 'index_map.pmtiles', md5_digest: 'existing-md5',
                                     sha1_digest: 'existing-sha1')
      end

      it 'sniffs the PMTiles mime type' do
        call

        expect(content_file_binary.mime_type).to eq('application/vnd.pmtiles')
      end
    end

    {
      'shapefile.shp' => 'application/vnd.shp',
      'shapefile.shx' => 'application/octet-stream',
      'SANB_a2725322.prj' => 'text/plain'
    }.each do |filepath, mime_type|
      context "when the file on a mount is #{filepath}" do
        let(:content_file_binary) do
          create(:content_file_binary, file_location: 'mount', mount_path: file_fixture_path, filepath:,
                                       md5_digest: 'existing-md5', sha1_digest: 'existing-sha1')
        end

        it "uses the #{mime_type} mime type" do
          call

          expect(content_file_binary.mime_type).to eq(mime_type)
        end
      end
    end

    context 'when the file on a mount is a GDAL overview' do
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'mount', mount_path: file_fixture_path, filepath: 'overview.ovr',
                                     md5_digest: 'existing-md5', sha1_digest: 'existing-sha1')
      end

      it 'uses the octet-stream mime type rather than sniffing a TIFF' do
        call

        expect(content_file_binary.mime_type).to eq('application/octet-stream')
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

        expect(content_file_binary.size).to eq(52)
      end
    end

    context 'when mime_type_only is true' do
      let(:mime_type_only) { true }
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'attached', filepath: 'dropzone_upload.txt')
      end

      before do
        content_file_binary.file.attach(fixture_file_upload('dropzone_upload.txt', 'text/plain'))
      end

      it 'populates the mime type but not the digests or size' do
        call

        expect(content_file_binary.reload).to have_attributes(
          mime_type: 'text/plain',
          md5_digest: nil,
          sha1_digest: nil,
          size: nil
        )
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

    context 'when the file is on a mount and the size is not yet set' do
      let(:content_file_binary) do
        create(:content_file_binary, file_location: 'mount', mount_path: file_fixture_path,
                                     filepath: 'catalog_record_id_and_barcode.xlsx',
                                     md5_digest: 'existing-md5', sha1_digest: 'existing-sha1', mime_type: 'text/plain')
      end

      it 'reads the size from the file on disk' do
        call

        expect(content_file_binary.size).to eq(8391)
      end
    end
  end
end
