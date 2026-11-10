# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'File downloads' do
  let(:druid) { 'druid:bc123df4567' }
  let(:token) do
    Rails.application.message_verifier(:argo).generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
  end
  let(:objects_client) { instance_double(Preservation::Client::Objects) }

  before do
    sign_in(create(:user))
    allow(Preservation::Client).to receive(:objects).and_return(objects_client)
  end

  describe 'GET /objects/:object_druid/file_download' do
    context 'when the file is staged' do
      let(:staged_filepath) { StagingSupport.staging_filepath(druid:, filepath: 'folder1/image1.tif') }

      before do
        FileUtils.mkdir_p(File.dirname(staged_filepath))
        File.write(staged_filepath, 'staged content')
        allow(objects_client).to receive(:content)
      end

      after { FileUtils.rm_rf(StagingSupport.staging_content_path(druid:)) }

      it 'sends the staged file as an attachment named by its basename' do
        get "/objects/#{token}/file_download", params: { filepath: 'folder1/image1.tif' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('staged content')
        expect(response.headers['Content-Type']).to eq('application/octet-stream')
        expect(response.headers['Content-Disposition']).to start_with('attachment; filename="image1.tif"')
        expect(objects_client).not_to have_received(:content)
      end
    end

    context 'when the file is not staged' do
      before do
        allow(objects_client).to receive(:content) do |on_data:, **|
          on_data.call('preserved ', 10)
          on_data.call('content', 7)
        end
      end

      it 'streams the latest preserved file' do
        get "/objects/#{token}/file_download", params: { filepath: 'folder1/image1.tif' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('preserved content')
        expect(response.headers['Content-Disposition']).to start_with('attachment; filename="image1.tif"')
        expect(objects_client).to have_received(:content).with(druid:, filepath: 'folder1/image1.tif',
                                                               on_data: an_instance_of(Proc))
      end
    end

    context 'when the file is neither staged nor preserved' do
      let(:stacks_url) { "#{Settings.stacks.file_url}/druid:bc123df4567/folder1/image1.tif" }

      before do
        allow(objects_client).to receive(:content).and_raise(Preservation::Client::NotFoundError, 'Not found')
        stub_request(:get, stacks_url).to_return(status: 200, body: 'stacks content')
      end

      it 'streams the file from stacks' do
        get "/objects/#{token}/file_download", params: { filepath: 'folder1/image1.tif' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('stacks content')
        expect(response.headers['Content-Disposition']).to start_with('attachment; filename="image1.tif"')
      end
    end

    context 'when the file is not staged, preserved, or provided by stacks' do
      let(:stacks_url) { "#{Settings.stacks.file_url}/druid:bc123df4567/folder1/image1.tif" }

      before do
        allow(objects_client).to receive(:content).and_raise(Preservation::Client::NotFoundError, 'Not found')
        stub_request(:get, stacks_url).to_return(status: 403, body: 'Forbidden')
      end

      it 'redirects to the object page with an error' do
        get "/objects/#{token}/file_download", params: { filepath: 'folder1/image1.tif' }

        expect(response).to redirect_to("/objects/#{druid}")
        expect(response.headers['Content-Disposition']).to be_nil
        expect(flash[:danger]).to eq('folder1/image1.tif is not available for download. ' \
                                     'If the object is being accessioned, try again when that has finished.')
      end
    end

    it 'returns forbidden when token verification fails' do
      get '/objects/not-a-valid-token/file_download', params: { filepath: 'folder1/image1.tif' }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
