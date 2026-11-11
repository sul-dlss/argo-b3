# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update workflow process' do
  let(:druid) { 'druid:bc123df4567' }
  let(:solr_doc) { { Search::Fields::ID => druid, Search::Fields::OBJECT_TYPES => ['item'] } }
  let(:user) { create(:user, :reader) }
  let(:process_client) { instance_double(Dor::Services::Client::Process, update: nil) }
  let(:workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow, process: process_client) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, workflow: workflow_client) }
  let(:path) { '/objects/druid:bc123df4567/workflows/accessionWF/processes/shelve' }
  let(:turbo_headers) { { 'Accept' => 'text/vnd.turbo-stream.html, text/html' } }

  before do
    allow(Sdr::Repository).to receive(:find_solr).with(druid:).and_return(solr_doc)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    sign_in(user)
  end

  context 'when the user can edit the object' do
    before do
      create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
    end

    it 'retries the process, shows a toast, and reloads the workflows frame' do
      patch path, params: { status: 'waiting', version: '2' }, headers: turbo_headers

      expect(workflow_client).to have_received(:process).with('shelve')
      expect(object_client).to have_received(:workflow).with('accessionWF')
      expect(process_client).to have_received(:update)
        .with(status: 'waiting', note: nil, version: '2', current_status: 'error')
      expect(response.body).to include('turbo-stream action="append" target="toast-container"')
      expect(response.body).to include('Retrying process.')
      expect(response.body).to include('turbo-stream action="append" target="druid:bc123df4567_workflows"')
      expect(response.body).to include('data-frame-reloader-reloadable-frame-outlet=".workflows-frame"')
      expect(response.body).not_to include('turbo-stream action="refresh"')
    end

    it 'does not allow skipping the process' do
      patch path, params: { status: 'skipped', version: '2' }

      expect(process_client).not_to have_received(:update)
      expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
    end

    it 'does not allow completing the process' do
      patch path, params: { status: 'completed', version: '2' }

      expect(process_client).not_to have_received(:update)
      expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
    end
  end

  context 'when the user cannot edit the object' do
    it 'does not allow retrying the process' do
      patch path, params: { status: 'waiting', version: '2' }

      expect(process_client).not_to have_received(:update)
      expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
    end
  end

  context 'when the user is an admin' do
    let(:user) { create(:user, :admin) }

    it 'skips the process with a note and shows a toast' do
      patch path, params: { status: 'skipped', version: '2' }, headers: turbo_headers

      expect(process_client).to have_received(:update)
        .with(status: 'skipped', note: "Skipped by #{user.sunetid}", version: '2', current_status: 'error')
      expect(response.body).to include('Skipped process.')
    end

    it 'completes the process with a note and shows a toast' do
      patch path, params: { status: 'completed', version: '2' }, headers: turbo_headers

      expect(process_client).to have_received(:update)
        .with(status: 'completed', note: "Completed by #{user.sunetid}", version: '2', current_status: 'error')
      expect(response.body).to include('Completed process.')
    end

    context 'when the process is no longer in error' do
      before do
        allow(process_client).to receive(:update)
          .and_raise(Dor::Services::Client::ConflictResponse.new(response: instance_double(Faraday::Response)))
      end

      it 'redirects to the object page with an alert' do
        patch path, params: { status: 'completed', version: '2' }, headers: turbo_headers

        expect(response).to redirect_to('/objects/druid:bc123df4567')
        expect(flash[:danger]).to eq('This process has changed since the page was loaded.')
      end
    end

    context 'when the update fails' do
      before do
        errors = [{ 'title' => 'Server error', 'detail' => 'Something broke' }]
        error = Dor::Services::Client::UnexpectedResponse.new(response: instance_double(Faraday::Response), errors:)
        allow(process_client).to receive(:update).and_raise(error)
      end

      it 'redirects to the object page with an alert' do
        patch path, params: { status: 'waiting', version: '2' }, headers: turbo_headers

        expect(response).to redirect_to('/objects/druid:bc123df4567')
        expect(flash[:danger]).to eq('Process could not be updated: Server error (Something broke)')
      end
    end
  end
end
