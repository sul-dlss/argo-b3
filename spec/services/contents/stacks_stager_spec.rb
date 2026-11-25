# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::StacksStager do
  let(:druid) { 'druid:bc123df4567' }
  let(:staging_location) { Settings.staging_location }
  let(:content) { create(:content, :mutable, druid:) }
  let(:content_file_set) { create(:content_file_set, content:) }
  let(:stacks_md5) { '7c4e72224ae4d461b058c72b3a40d7e4' }
  let(:md5_digest) { stacks_md5 }
  let(:preserve) { true }
  let(:file_location) { 'deposited' }
  let(:version) { 2 }
  let(:content_file_binary) do
    create(:content_file_binary, content:, file_location:, filepath: 'folder1/image1.jp2', md5_digest:)
  end
  let(:catalog_md5) { '0c84751f0ca9c6886bb09f2dd1a66faa' }
  let(:signature_catalog) do
    Moab::SignatureCatalog.parse(<<~XML)
      <signatureCatalog objectId="druid:bc123df4567" versionId="1">
        <entry originalVersion="1" groupId="content" storagePath="image1.tif">
          <fileSignature size="13" md5="#{catalog_md5}" sha1="abc" sha256="def"/>
        </entry>
        <entry originalVersion="1" groupId="metadata" storagePath="cocina.json">
          <fileSignature size="14" md5="#{stacks_md5}" sha1="abc" sha256="def"/>
        </entry>
      </signatureCatalog>
    XML
  end
  let(:objects_client) { instance_double(Preservation::Client::Objects, signature_catalog:) }
  let(:stacks_url) { "#{Settings.stacks.file_url}/druid:bc123df4567/folder1/image1.jp2" }
  let(:staged_filepath) { File.join(staging_location, 'bc/123/df/4567/bc123df4567/content/folder1/image1.jp2') }

  before do
    create(:content_file, content_file_set:, content_file_binary:, preserve:)
    allow(Preservation::Client).to receive(:objects).and_return(objects_client)
    stub_request(:get, stacks_url).to_return(status: 200, body: 'stacks content')
  end

  after do
    FileUtils.rm_rf(StagingSupport.staging_content_path(druid:, staging_location:))
  end

  def stage
    described_class.call(content:, staging_location:, version:)
  end

  context 'when a deposited, preserved file is not in preservation' do
    it 'stages the file from Stacks' do
      stage

      expect(File.read(staged_filepath)).to eq('stacks content')
      expect(content_file_binary.reload.file_location).to eq('stage')
      expect(objects_client).to have_received(:signature_catalog).with(druid)
    end
  end

  context 'when the file is in preservation' do
    let(:catalog_md5) { stacks_md5 }

    it 'does not stage the file' do
      stage

      expect(a_request(:get, stacks_url)).not_to have_been_made
      expect(content_file_binary.reload.file_location).to eq('deposited')
    end
  end

  context 'when the object is not in preservation' do
    let(:stager) { described_class.new(content:, staging_location:, version:) }

    before do
      allow(objects_client).to receive(:signature_catalog).and_raise(Preservation::Client::NotFoundError)
      allow(stager).to receive(:sleep)
    end

    it 'retries, then raises without trying Stacks' do
      expect { stager.call }.to raise_error(described_class::PreservationNotFoundError, /#{druid}/)

      expect(objects_client).to have_received(:signature_catalog).exactly(5).times
      expect(stager).to have_received(:sleep).exactly(4).times
      expect(a_request(:get, stacks_url)).not_to have_been_made
      expect(content_file_binary.reload.file_location).to eq('deposited')
    end
  end

  context 'when Preservation has the object only on retry' do
    let(:stager) { described_class.new(content:, staging_location:, version:) }
    let(:catalog_md5) { stacks_md5 }

    before do
      responses = [:not_found, signature_catalog]
      allow(objects_client).to receive(:signature_catalog) do
        response = responses.shift
        response == :not_found ? raise(Preservation::Client::NotFoundError) : response
      end
      allow(stager).to receive(:sleep)
    end

    it 'uses the retried signature catalog' do
      stager.call

      expect(stager).to have_received(:sleep).once
      expect(a_request(:get, stacks_url)).not_to have_been_made
      expect(content_file_binary.reload.file_location).to eq('deposited')
    end
  end

  context 'when the object is at its first version' do
    let(:version) { 1 }

    before do
      allow(objects_client).to receive(:signature_catalog).and_raise(Preservation::Client::NotFoundError)
    end

    it 'does not check preservation or stage the file' do
      stage

      expect(objects_client).not_to have_received(:signature_catalog)
      expect(a_request(:get, stacks_url)).not_to have_been_made
      expect(content_file_binary.reload.file_location).to eq('deposited')
    end
  end

  context 'when the file is not preserved' do
    let(:preserve) { false }

    it 'does not check preservation or stage the file' do
      stage

      expect(objects_client).not_to have_received(:signature_catalog)
      expect(content_file_binary.reload.file_location).to eq('deposited')
    end
  end

  context 'when the file is not deposited' do
    let(:file_location) { 'stage' }

    it 'does not check preservation' do
      stage

      expect(objects_client).not_to have_received(:signature_catalog)
    end
  end

  context 'when Stacks does not provide the file' do
    let(:other_content_file_binary) do
      create(:content_file_binary, content:, file_location: 'deposited', filepath: 'image2.jp2',
                                   md5_digest: stacks_md5)
    end

    before do
      create(:content_file, content_file_set:, content_file_binary: other_content_file_binary, position: 2)
      stub_request(:get, stacks_url).to_return(status: 403)
      stub_request(:get, "#{Settings.stacks.file_url}/druid:bc123df4567/image2.jp2")
        .to_return(status: 200, body: 'stacks content')
      allow(Honeybadger).to receive(:notify)
    end

    it 'stages the other files and raises naming the file that failed' do
      expect { stage }.to raise_error(described_class::Error) { |error|
        expect(error.filepaths).to eq(['folder1/image1.jp2'])
      }

      expect(File.exist?(staged_filepath)).to be false
      expect(content_file_binary.reload.file_location).to eq('deposited')
      expect(other_content_file_binary.reload.file_location).to eq('stage')
      expect(Honeybadger).to have_received(:notify)
        .with(Sdr::StacksFile::NotFoundError, context: { druid:, filepath: 'folder1/image1.jp2' })
    end
  end

  context 'when the download fails' do
    before do
      stub_request(:get, stacks_url).to_timeout
      allow(Honeybadger).to receive(:notify)
    end

    it 'raises naming the file' do
      expect { stage }.to raise_error(described_class::Error, 'Could not stage from Stacks: folder1/image1.jp2')
      expect(File.exist?(staged_filepath)).to be false
    end
  end

  context 'when the file from Stacks does not match the MD5' do
    let(:md5_digest) { 'ffffffffffffffffffffffffffffffff' }

    before do
      allow(Honeybadger).to receive(:notify)
    end

    it 'raises without staging the file' do
      expect { stage }.to raise_error(described_class::Error, 'Could not stage from Stacks: folder1/image1.jp2')

      expect(Dir.glob("#{File.dirname(staged_filepath)}/*")).to be_empty
      expect(content_file_binary.reload.file_location).to eq('deposited')
      expect(Honeybadger).to have_received(:notify).with(described_class::IntegrityError, anything)
    end
  end
end
