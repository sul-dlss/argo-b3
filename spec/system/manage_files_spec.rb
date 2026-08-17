# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Manage files' do
  let(:druid) { 'druid:bc123df4567' }
  let(:title) { 'My title' }

  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let!(:user) { create(:user) }

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, milestones: milestones_client,
                                                   user_version: user_version_client, lock: 'abc123')
  end
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: [], status: version_status) }
  let(:version_status) do
    instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, accessioning?: false, closed?: false)
  end
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: []) }
  let(:milestones_client) { instance_double(Dor::Services::Client::Milestones, list: []) }

  before do
    sign_in(user)

    allow(Sdr::Repository).to receive_messages(find: cocina_object,
                                               find_solr: build(:solr_item, druid:, title:))
    allow(StageFilesJob).to receive(:perform_later)
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
    allow(PurlPreviewService).to receive(:call).and_return('<html><body><main></main></body></html>')
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  it 'displays the object title and all tabs, uploads a file, and deposits' do
    visit "/contents/#{druid}/edit"

    expect(page).to have_css('p', text: title)

    expect(page).to have_css('.nav-link', text: 'Add files')
    expect(page).to have_css('.nav-link', text: 'Manage files')
    expect(page).to have_css('.nav-link', text: 'Deposit')

    attach_file(nil, Rails.root.join('spec/fixtures/files/dropzone_upload.txt'), make_visible: true)

    click_on 'Manage files'

    expect(page).to have_css('li', text: 'dropzone_upload.txt')

    content = Content.find_by!(druid:)
    content_file_set = content.content_file_sets.sole
    expect(content_file_set).to have_attributes(file_set_type: 'object')

    content_file = content_file_set.content_files.sole
    content_file_binary = content_file.content_file_binary
    expect(content_file_binary).to have_attributes(filepath: 'dropzone_upload.txt', file_location: 'attached')
    expect(content_file_binary.file).to be_attached
    expect(content_file_binary.file.filename.to_s).to eq('dropzone_upload.txt')

    click_on 'Deposit'
    click_button('Deposit')

    expect(page).to have_current_path("/objects/#{druid}")

    expect(StageFilesJob).to have_received(:perform_later).with(content:, accession: true, user:)
  end
end
