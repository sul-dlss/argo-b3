# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sdr::StacksFile do
  describe '.stream' do
    let(:url) { "#{Settings.stacks.file_url}/druid:bc123df4567/folder%201/image%201.tif" }
    let(:chunks) { [] }

    def stream
      described_class.stream(druid: 'druid:bc123df4567', filepath: 'folder 1/image 1.tif') { |chunk| chunks << chunk }
    end

    context 'when stacks returns the file' do
      before do
        stub_request(:get, url).to_return(status: 200, body: 'stacks content')
      end

      it 'yields the file' do
        stream

        expect(chunks.join).to eq('stacks content')
      end
    end

    context 'with a service token' do
      before do
        allow(Settings.stacks).to receive(:token).and_return('my-token')
        stub_request(:get, url).with(headers: { 'Authorization' => 'Bearer my-token' })
                               .to_return(status: 200, body: 'stacks content')
      end

      it 'sends the token' do
        stream

        expect(chunks.join).to eq('stacks content')
      end
    end

    context 'when stacks redirects to another host' do
      let(:signed_url) { 'https://s3.example.com/bucket/bc123df4567/image%201.tif?X-Amz-Signature=abc' }

      before do
        allow(Settings.stacks).to receive(:token).and_return('my-token')
        stub_request(:get, url).to_return(status: 302, headers: { 'Location' => signed_url })
        stub_request(:get, signed_url).to_return(status: 200, body: 's3 content')
      end

      it 'yields the file from the redirect without sending the service token' do
        stream

        expect(chunks.join).to eq('s3 content')
        expect(a_request(:get, signed_url).with(headers: { 'Authorization' => 'Bearer my-token' }))
          .not_to have_been_made
      end
    end

    context 'when stacks redirects within stacks (e.g., to log in)' do
      let(:auth_url) { "#{Settings.stacks.file_url}/auth/druid:bc123df4567/folder%201/image%201.tif" }

      before do
        stub_request(:get, url).to_return(status: 302, headers: { 'Location' => auth_url })
        stub_request(:get, auth_url).to_return(status: 200, body: 'login page')
      end

      it 'raises without following the redirect' do
        expect { stream }.to raise_error(described_class::NotFoundError)
        expect(chunks).to be_empty
        expect(a_request(:get, auth_url)).not_to have_been_made
      end
    end

    context 'when the redirect target does not provide the file' do
      let(:signed_url) { 'https://s3.example.com/bucket/bc123df4567/image%201.tif?X-Amz-Signature=abc' }

      before do
        stub_request(:get, url).to_return(status: 302, headers: { 'Location' => signed_url })
        stub_request(:get, signed_url).to_return(status: 403, body: 'Expired')
      end

      it 'raises without yielding' do
        expect { stream }.to raise_error(described_class::NotFoundError)
        expect(chunks).to be_empty
      end
    end

    context 'when stacks does not provide the file' do
      before do
        stub_request(:get, url).to_return(status: 403, body: 'Forbidden')
      end

      it 'raises without yielding' do
        expect { stream }.to raise_error(described_class::NotFoundError)
        expect(chunks).to be_empty
      end
    end
  end
end
