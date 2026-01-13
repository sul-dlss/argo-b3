# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ExportCocinaJsonJob do
  subject(:job) { described_class.new(bulk_action:, druids: [druid]) }

  let(:druid) { 'druid:hj185xx2222' }
  let(:bulk_action) { create(:bulk_action, action_type: 'export_cocina_json') }

  let(:unzipped_path) { bulk_action.filepath_for(filename: 'unzipped_file.jsonl') }

  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:log) { StringIO.new }

  let(:job_item) do
    described_class::Item.new(druid:, index: 0, job:).tap do |job_item|
      allow(job_item).to receive(:cocina_object).and_return(cocina_object)
    end
  end

  before do
    allow(described_class::Item).to receive(:new).and_return(job_item)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
  end

  after do
    bulk_action.remove_output_directory!
  end

  it 'performs the job' do
    job.perform_now

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)

    expect(File).not_to exist(bulk_action.filepath_for(filename: 'cocina.jsonl'))

    expect(File).to exist(bulk_action.export_filepath)
    File.write(unzipped_path, ActiveSupport::Gzip.decompress(File.read(bulk_action.export_filepath)))
    expect(File.open(unzipped_path).readlines.size).to eq 1
  end
end
