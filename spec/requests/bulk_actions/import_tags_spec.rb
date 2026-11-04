# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Import tags bulk action' do
  let(:user) { create(:user) }
  let(:csv_file) { Rack::Test::UploadedFile.new(tempfile.path, 'text/csv') }
  let(:tempfile) { Tempfile.new(['upload', '.csv']).tap { |file| file.write(csv) && file.flush } }
  let(:csv) { "bc123df4567,Project : Testing,Test Tag : Testing 2\nfg456hj7890\n" }
  let(:form_params) do
    {
      bulk_actions_import_tags: {
        csv_file:,
        description: 'Import tags'
      }
    }
  end

  before do
    sign_in(user)
  end

  it 'renders the new page' do
    get new_bulk_actions_import_tags_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('To remove all tags from an object, include only the druid.')
  end

  it 'creates the bulk action and enqueues the job' do
    expect do
      post bulk_actions_import_tags_path, params: form_params
    end.to have_enqueued_job(BulkActions::ImportTagsJob)
      .with(bulk_action: instance_of(BulkAction),
            csv_file: "druid:bc123df4567,Project : Testing,Test Tag : Testing 2\ndruid:fg456hj7890\n")

    expect(response).to redirect_to(bulk_actions_path)
    expect(BulkAction.last.action_type).to eq('IMPORT_TAGS')
  end

  context 'when the csv_file is invalid' do
    let(:csv) { "bc123df4567,Testing\n" }

    it 'renders the form with the error and does not create the bulk action' do
      post bulk_actions_import_tags_path, params: form_params

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('row 1: invalid tags: Testing')
      expect(BulkAction.count).to eq(0)
    end
  end
end
