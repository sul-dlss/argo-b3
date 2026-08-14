# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show files' do
  let(:druid) { 'druid:bc123df4567' }
  let(:token) do
    Rails.application.message_verifier(:argo).generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
  end
  let(:invalid_token) { 'not-a-valid-token' }
  let(:cocina_object) { Cocina::Models.with_metadata(Cocina::Models.build(JSON.parse(json)), 'abc123') }
  let(:json) do
    <<~JSON
      {
        "type": "#{Cocina::Models::ObjectType.image}",
        "externalIdentifier": "#{druid}",
        "version": 1,
        "access": {
          "view": "world",
          "download": "world"
        },
        "administrative": {
          "hasAdminPolicy": "druid:fh940mz2717"
        },
        "description": {
          "title": [
            {
              "value": "Show files test object"
            }
          ],
          "purl": "https://purl.stanford.edu/bc123df4567",
          "access": {
            "digitalRepository": [
              {
                "value": "Stanford Digital Repository"
              }
            ]
          }
        },
        "identification": {
          "sourceId": "foo:129"
        },
        "structural": {
          "contains": [
            {
              "type": "#{Cocina::Models::FileSetType.image}",
              "externalIdentifier": "https://cocina.sul.stanford.edu/fileSet/e43590ae-abf9-4a5c-88f2-a8627969dc23",
              "label": "Image 1",
              "version": 1,
              "structural": {
                "contains": [
                  {
                    "type": "#{Cocina::Models::ObjectType.file}",
                    "externalIdentifier": "https://cocina.sul.stanford.edu/file/de24d694-2fe8-41a5-9113-ae6adf4506fd",
                    "label": "Image 1 file",
                    "filename": "folder1/bc123df4567_0001.tiff",
                    "version": 1,
                    "hasMessageDigests": [],
                    "access": {
                      "view": "world",
                      "download": "world"
                    },
                    "administrative": {
                      "publish": true,
                      "sdrPreserve": true,
                      "shelve": true
                    }
                  }
                ]
              }
            }
          ]
        }
      }
    JSON
  end

  before do
    sign_in(create(:user))
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
  end

  describe 'GET /objects/:druid/files' do
    it 'renders the list of file paths' do
      get "/objects/#{token}/files"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('folder1/bc123df4567_0001.tiff')
    end

    it 'raises when token verification fails' do
      get "/objects/#{invalid_token}/files"

      expect(response).to have_http_status(:forbidden)
    end
  end
end
