# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurlPreviewService do
  subject(:body) { described_class.call(cocina_hash:, constituent_of:) }

  let(:constituent_of) { [] }
  let(:cocina_hash) do
    {
      externalIdentifier: 'druid:bc123cd4567',
      description: { title: [{ value: 'Test object' }] }
    }
  end
  let(:response) { instance_double(Faraday::Response, success?: success, status:, body: response_body) }
  let(:status) { 200 }
  let(:response_body) { '<html><body>preview</body></html>' }

  before do
    allow(Faraday).to receive(:post).and_return(response)
  end

  context 'when the preview request succeeds' do
    let(:success) { true }

    it 'posts the cocina JSON and returns the response body' do
      expect(body).to eq(response_body)
      expect(Faraday).to have_received(:post).with(
        "#{Settings.purl.url}/preview",
        { cocina: cocina_hash.to_json }.to_json,
        'Content-Type' => 'application/json'
      )
    end
  end

  context 'when the object is a constituent of virtual objects' do
    let(:success) { true }
    let(:cocina_hash) do
      {
        externalIdentifier: 'druid:bc123cd4567',
        description: { title: [{ value: 'Test object' }],
                       relatedResource: [{ title: [{ value: 'Related' }], type: 'related to' }] }
      }
    end
    let(:constituent_of) { [['druid:bb777bb7777', 'Map set']] }
    let(:expected_cocina_hash) do
      {
        externalIdentifier: 'druid:bc123cd4567',
        description: {
          title: [{ value: 'Test object' }],
          relatedResource: [
            { title: [{ value: 'Related' }], type: 'related to' },
            { title: [{ value: 'Map set' }], type: 'part of', purl: "#{Settings.purl.url}/bb777bb7777",
              displayLabel: 'Appears in' }
          ]
        }
      }
    end

    it 'posts the cocina JSON with an "Appears in" related resource for each virtual object' do
      body
      expect(Faraday).to have_received(:post).with(
        "#{Settings.purl.url}/preview",
        { cocina: expected_cocina_hash.to_json }.to_json,
        'Content-Type' => 'application/json'
      )
    end
  end

  context 'when the preview request fails' do
    let(:success) { false }
    let(:status) { 500 }
    let(:response_body) { 'Internal Server Error' }

    it 'raises an error with the response details' do
      expect { body }.to raise_error(
        described_class::Error,
        'Purl preview request failed: 500 Internal Server Error'
      )
    end
  end
end
