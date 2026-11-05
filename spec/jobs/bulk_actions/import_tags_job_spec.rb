# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ImportTagsJob do
  subject(:job) { described_class.new(bulk_action:, csv_file:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:other_druid) { 'druid:fg456hj7890' }
  let(:csv_file) { "#{druid},Project : Testing,Test Tag : Testing 2\n#{other_druid}\n" }

  let(:bulk_action) { create(:bulk_action, action_type: 'IMPORT_TAGS', user:) }
  let(:user) { create(:user, :admin) }
  let(:log) { StringIO.new }

  let(:tags_client) { instance_double(Dor::Services::Client::AdministrativeTags, replace: true) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, administrative_tags: tags_client) }
  let(:other_tags_client) do
    instance_double(Dor::Services::Client::AdministrativeTags,
                    list: ['Old Tag : One', 'Project : Old'], destroy: true)
  end
  let(:other_object_client) { instance_double(Dor::Services::Client::Object, administrative_tags: other_tags_client) }

  before do
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(build(:dro_with_metadata, id: druid))
    allow(Sdr::Repository).to receive(:find).with(druid: other_druid)
                                            .and_return(build(:collection_with_metadata, id: other_druid))
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(Dor::Services::Client).to receive(:object).with(other_druid).and_return(other_object_client)
  end

  it 'replaces the tags, or removes them all when a row has no tags' do
    job.perform_now

    expect(tags_client).to have_received(:replace).with(tags: ['Project : Testing', 'Test Tag : Testing 2'])
    expect(other_tags_client).to have_received(:destroy).with(tag: 'Old Tag : One')
    expect(other_tags_client).to have_received(:destroy).with(tag: 'Project : Old')

    expect(log.string).to include("line 1\t#{druid}\tSuccess: Replaced tags (Project : Testing, Test Tag : Testing 2)")
    expect(log.string).to include("line 2\t#{other_druid}\tSuccess: Removed all tags")
    expect(bulk_action.reload.druid_count_total).to eq(2)
    expect(bulk_action.druid_count_success).to eq(2)
    expect(bulk_action.druid_count_fail).to eq(0)
  end

  context 'when the user lacks update permission' do
    let(:user) { create(:user) }

    it 'does not change the tags' do
      job.perform_now

      expect(tags_client).not_to have_received(:replace)
      expect(other_tags_client).not_to have_received(:destroy)
      expect(log.string).to include("line 1\t#{druid}\tError: Not authorized to update")
      expect(bulk_action.reload.druid_count_fail).to eq(2)
    end
  end

  context 'when the object is not found' do
    before do
      allow(Sdr::Repository).to receive(:find).with(druid:).and_raise(Sdr::Repository::NotFoundResponse)
    end

    it 'records the failure' do
      job.perform_now

      expect(tags_client).not_to have_received(:replace)
      expect(log.string).to include("line 1\t#{druid}\tError: Object not found")
      expect(bulk_action.reload.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end

  context 'when DSA rejects the tags' do
    let(:response) { instance_double(Faraday::Response, status: 409, body: nil, reason_phrase: 'Conflict') }

    before do
      allow(tags_client).to receive(:replace).and_raise(Dor::Services::Client::UnexpectedResponse.new(response:))
    end

    it 'records the failure' do
      job.perform_now

      expect(log.string)
        .to include("line 1\t#{druid}\tError: Sdr::AdministrativeTags::Error Replacing administrative tags failed")
      expect(bulk_action.reload.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end
end
