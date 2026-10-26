# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create virtual object bulk action' do
  let(:user) { create(:user) }
  let(:csv_file) { Rack::Test::UploadedFile.new(tempfile.path, 'text/csv') }
  let(:tempfile) { Tempfile.new(['upload', '.csv']).tap { |file| file.write(csv) && file.flush } }
  let(:csv) { "bc123df4567,cd234fg5678,df345gh6789\n" }
  let(:form_params) do
    {
      bulk_actions_create_virtual_object: {
        csv_file:,
        description: 'Create virtual objects'
      }
    }
  end

  before do
    sign_in(user)
  end

  it 'renders the new page' do
    get new_bulk_actions_create_virtual_object_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Do not include column headers.')
  end

  it 'creates the bulk action and enqueues the job' do
    expect do
      post bulk_actions_create_virtual_object_path, params: form_params
    end.to have_enqueued_job(BulkActions::CreateVirtualObjectJob)
      .with(bulk_action: instance_of(BulkAction),
            csv_file: "druid:bc123df4567,druid:cd234fg5678,druid:df345gh6789\n")

    expect(response).to redirect_to(bulk_actions_path)
    expect(BulkAction.last.action_type).to eq('CREATE_VIRTUAL_OBJECT')
  end

  context 'when the csv_file is a spreadsheet' do
    let(:csv_file) { fixture_file_upload('create_virtual_object.xlsx') }

    it 'creates the bulk action and enqueues the job' do
      expect do
        post bulk_actions_create_virtual_object_path, params: form_params
      end.to have_enqueued_job(BulkActions::CreateVirtualObjectJob)
        .with(bulk_action: instance_of(BulkAction),
              csv_file: "druid:bc123df4567,druid:cd234fg5678,druid:df345gh6789\n" \
                        "druid:fg456hj7890,druid:hj567km8901\n")

      expect(response).to redirect_to(bulk_actions_path)
    end
  end

  context 'when the csv_file is invalid' do
    let(:csv) { "bc123df4567\n" }

    it 'renders the form with the error and does not create the bulk action' do
      post bulk_actions_create_virtual_object_path, params: form_params

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('row 1: no constituent druids')
      expect(BulkAction.count).to eq(0)
    end
  end
end
