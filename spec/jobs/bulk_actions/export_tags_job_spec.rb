# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ExportTagsJob do
  subject(:job) { described_class.new(bulk_action:, druids: [druid]) }

  let(:druid) { 'druid:bc123df4567' }

  let(:bulk_action) { create(:bulk_action, action_type: 'export_tags', user:) }
  let(:user) { create(:user, :reader) }
  let(:csv_path) { bulk_action.export_filepath(:tags) }
  let(:log) { StringIO.new }

  let(:object_client) { instance_double(Dor::Services::Client::Object, administrative_tags: tags_client) }
  let(:tags_client) { instance_double(Dor::Services::Client::AdministrativeTags, list: tags) }
  let(:tags) { ['Project : Testing 2', 'Test Tag : Testing 3'] }

  before do
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(build(:dro_with_metadata, id: druid))
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  after do
    bulk_action.remove_output_directory!
  end

  it 'performs the job' do
    job.perform_now

    expect(Dor::Services::Client).to have_received(:object).with(druid)
    expect(tags_client).to have_received(:list).once

    expect(File).to exist(csv_path)
    output = CSV.read(csv_path)
    expect(output.first.to_csv).to eq "bc123df4567,Project : Testing 2,Test Tag : Testing 3\n"

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
  end

  context 'when the user lacks read permission' do
    let(:user) { create(:user) }

    it 'does not export the tags' do
      job.perform_now

      expect(tags_client).not_to have_received(:list)
      expect(CSV.read(csv_path)).to be_empty

      expect(bulk_action.reload.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(log.string).to include "#{druid}\tError: Not authorized to read"
    end
  end
end
