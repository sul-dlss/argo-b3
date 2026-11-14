# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileDownloadService do
  subject(:file_download) { described_class.new(druid:, filepath: 'image1.tif') }

  let(:druid) { 'druid:bc123df4567' }
  let(:objects_client) { instance_double(Preservation::Client::Objects) }
  let(:stacks_url) { "#{Settings.stacks.file_url}/druid:bc123df4567/image1.tif" }

  before do
    allow(Preservation::Client).to receive(:objects).and_return(objects_client)
  end

  describe '#headers' do
    before do
      allow(objects_client).to receive(:content) { |on_data:, **| on_data.call('preserved content', 17) }
    end

    context 'when no Content has the file' do
      it 'has no Content-Length' do
        expect(file_download.headers).to eq({})
      end
    end
  end

  describe '#call' do
    let(:stream) { StringIO.new }

    context 'when preservation fails after streaming has started' do
      before do
        allow(objects_client).to receive(:content) do |on_data:, **|
          on_data.call('preserved ', 10)
          raise Preservation::Client::ConnectionFailedError, 'Timeout'
        end
        allow(Rails.error).to receive(:report)
        allow(Rails.logger).to receive(:error)
      end

      it 'logs and reports the error and closes the stream after the streamed chunks' do
        file_download.call(stream)

        expect(stream.string).to eq('preserved ')
        expect(stream).to be_closed
        expect(Rails.error).to have_received(:report).with(an_instance_of(Preservation::Client::ConnectionFailedError))
        expect(Rails.logger).to have_received(:error)
          .with('File download of image1.tif for druid:bc123df4567 failed: ' \
                'Preservation::Client::ConnectionFailedError: Timeout')
      end
    end

    context 'when no source has the file' do
      before do
        allow(objects_client).to receive(:content).and_raise(Preservation::Client::NotFoundError, 'Not found')
        stub_request(:get, stacks_url).to_return(status: 404)
        allow(Rails.error).to receive(:report)
        allow(Rails.logger).to receive(:warn)
      end

      it 'logs without reporting, and writes nothing' do
        file_download.call(stream)

        expect(stream.string).to eq('')
        expect(stream).to be_closed
        expect(Rails.logger).to have_received(:warn)
          .with('File download of image1.tif for druid:bc123df4567 not available: ' \
                'Stacks returned 404 for druid:bc123df4567 (image1.tif)')
        expect(Rails.error).not_to have_received(:report)
      end
    end

    context 'when the staged file is empty' do
      let(:staged_filepath) { StagingSupport.staging_filepath(druid:, filepath: 'image1.tif') }

      before do
        FileUtils.mkdir_p(File.dirname(staged_filepath))
        FileUtils.touch(staged_filepath)
      end

      after { FileUtils.rm_rf(StagingSupport.staging_content_path(druid:)) }

      it 'writes nothing' do
        file_download.call(stream)

        expect(stream.string).to eq('')
        expect(stream).to be_closed
      end
    end
  end
end
