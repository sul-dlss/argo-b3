# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show structure' do
  let(:druid) { 'druid:bc123df4567' }
  let(:token) do
    Rails.application.message_verifier(:argo).generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
  end
  let(:invalid_token) { 'not-a-valid-token' }
  let(:cocina_object) { Cocina::Models.with_metadata(Cocina::Models.build(cocina_hash), 'abc123') }
  let(:cocina_object_without_contains) do
    Cocina::Models.with_metadata(Cocina::Models.build(cocina_hash.merge(structural: {})), 'abc123')
  end
  let(:cocina_hash) do
    {
      type: Cocina::Models::ObjectType.image,
      externalIdentifier: druid,
      version: 1,
      access: {
        view: 'world',
        download: 'world'
      },
      administrative: {
        hasAdminPolicy: 'druid:fh940mz2717'
      },
      description: {
        title: [
          {
            value: 'Show structure test object'
          }
        ],
        purl: 'https://purl.stanford.edu/bc123df4567',
        access: {
          digitalRepository: [
            {
              value: 'Stanford Digital Repository'
            }
          ]
        }
      },
      identification: {
        sourceId: 'foo:129'
      },
      structural: {
        contains: [
          {
            type: Cocina::Models::FileSetType.image,
            externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/e43590ae-abf9-4a5c-88f2-a8627969dc23',
            label: 'Image 1',
            version: 1,
            structural: {
              contains: [
                {
                  type: Cocina::Models::ObjectType.file,
                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/de24d694-2fe8-41a5-9113-ae6adf4506fd',
                  label: 'Image 1 file',
                  filename: 'folder1/bc123df4567_0001.tiff',
                  version: 1,
                  hasMessageDigests: [],
                  access: {
                    view: 'world',
                    download: 'world'
                  },
                  administrative: {
                    publish: true,
                    sdrPreserve: true,
                    shelve: true
                  }
                }
              ]
            }
          }
        ]
      }
    }
  end

  before do
    sign_in(create(:user))
    allow(Sdr::Repository).to receive(:find).with(druid:, without_structural_contains: true)
                                            .and_return(cocina_object_without_contains)
    allow(Sdr::Repository).to receive(:find).with(druid:, without_structural_contains: false).and_return(cocina_object)
    allow(Sdr::WorkflowService).to receive(:accessioned?).and_return(true)
  end

  describe 'GET /objects/:druid/structure' do
    it 'renders the resources' do
      get "/objects/#{token}/structure"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Resources (1)')
      expect(response.body).to include('Images (1)')
      expect(response.body).to include('Image 1')
      expect(response.body).to include('folder1/bc123df4567_0001.tiff')
      expect(response.body)
        .to include("href=\"/objects/#{token}/file_download?filepath=folder1%2Fbc123df4567_0001.tiff\"")
    end

    it 'renders the download files bulk action button' do
      get "/objects/#{token}/structure"

      page = Capybara.string(response.body)
      expect(page).to have_css("form[action='/objects/#{token}/download_files_bulk_action'] " \
                               'button:not([disabled])', text: 'Start download files bulk action')
      expect(page).to have_no_text('No files are available to download.')
    end

    context 'when no file is available' do
      let(:cocina_hash) do
        super().tap do |hash|
          hash[:structural][:contains][0][:structural][:contains][0][:administrative][:shelve] = false
        end
      end

      before do
        allow(Sdr::WorkflowService).to receive(:accessioned?).and_return(false)
      end

      it 'disables the download files bulk action button' do
        get "/objects/#{token}/structure"

        page = Capybara.string(response.body)
        expect(page).to have_button('Start download files bulk action', disabled: true)
        expect(page).to have_text('No files are available to download.')
      end
    end

    context 'when the content is invalid for the content type' do
      # Published files in a file resource are an error for a book.
      let(:cocina_object) do
        Cocina::Models.with_metadata(Cocina::Models.build(cocina_hash.merge(type: Cocina::Models::ObjectType.book)),
                                     'abc123')
      end

      let(:version_service) do
        instance_double(Sdr::VersionService, open?: true, version: 1)
      end

      before do
        # Registered: the content is validated since the item has files.
        allow(Sdr::VersionService).to receive(:new).with(druid:).and_return(version_service)
      end

      it 'renders the content errors after the heading' do
        get "/objects/#{token}/structure"

        expect(response).to have_http_status(:ok)
        expect(response.body).to match(/Resources \(1\).*Content errors.*Resource 1 \(Image 1\) has published/m)
      end
    end

    context 'when the item has no files' do
      let(:cocina_hash) { super().merge(structural: {}) }
      let(:version_service) do
        instance_double(Sdr::VersionService, open?: true, version: 1)
      end

      before do
        allow(Sdr::VersionService).to receive(:new).with(druid:).and_return(version_service)
      end

      context 'when the item is registered' do
        it 'does not render the content warnings' do
          get "/objects/#{token}/structure"

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Resources (0)')
          expect(response.body).not_to include('Content warnings')
        end
      end

      context 'when the item is a draft' do
        let(:version_service) do
          instance_double(Sdr::VersionService, open?: true, version: 2)
        end

        it 'renders the content warnings' do
          get "/objects/#{token}/structure"

          expect(response.body).to include('Content warnings')
        end
      end

      context 'when the item is deposited' do
        let(:version_service) do
          instance_double(Sdr::VersionService, open?: false, version: 1)
        end

        it 'renders the content warnings' do
          get "/objects/#{token}/structure"

          expect(response.body).to include('Content warnings')
        end
      end
    end

    it 'raises when token verification fails' do
      get "/objects/#{invalid_token}/structure"

      expect(response).to have_http_status(:forbidden)
    end
  end
end
