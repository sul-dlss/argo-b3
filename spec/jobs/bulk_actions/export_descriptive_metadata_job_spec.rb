# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/IndexedLet
RSpec.describe BulkActions::ExportDescriptiveMetadataJob do
  subject(:job) { described_class.new(bulk_action:, druids:) }

  let(:bulk_action) { create(:bulk_action, action_type: 'export_descriptive_metadata') }
  let(:csv_path) { bulk_action.export_filepath }
  let(:log) { instance_double(File, puts: nil, close: true) }

  let(:druids) { [druid1, druid2, druid3] }
  let(:druid1) { 'druid:bc123df4567' }
  let(:druid2) { 'druid:bd123fg5678' }
  let(:druid3) { 'druid:bf123fg5678' }
  let(:item1) do
    build(:dro_with_metadata, id: druid1, source_id: 'sul:4444')
  end
  let(:item2) do
    build(:dro_with_metadata, id: druid2, title: 'Test DRO #2')
  end

  before do
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
    allow(Sdr::Repository).to receive(:find).with(druid: druid1).and_return(item1)
    allow(Sdr::Repository).to receive(:find).with(druid: druid2).and_return(item2)
  end

  after do
    FileUtils.rm_f(csv_path)
  end

  context 'when happy path' do
    let(:response) { instance_double(Faraday::Response, status: 500, body: nil, reason_phrase: 'Something went wrong') }

    before do
      allow(Sdr::Repository).to receive(:find).with(druid: druid3).and_raise(Dor::Services::Client::UnexpectedResponse.new(response:))
    end

    it 'writes a CSV file' do
      job.perform_now

      csv = CSV.read(csv_path, headers: true)
      expect(csv.headers).to eq ['druid', 'source_id', 'title1.value', 'purl']
      expect(csv[0][0]).to eq(druid1)
      expect(csv[1][0]).to eq(druid2)
      expect(csv[0][1]).to eq 'sul:4444'
      expect(csv[1][1]).to eq 'sul:1234'
      expect(csv[1]['title1.value']).to eq 'Test DRO #2'

      expect(bulk_action.druid_count_success).to eq 2
      expect(bulk_action.druid_count_fail).to eq 1
      expect(bulk_action.druid_count_total).to eq 3
    end
  end

  context 'when APO included among druids' do
    let(:item3) { build(:admin_policy_with_metadata, id: druid3) }

    before do
      allow(Sdr::Repository).to receive(:find).with(druid: druid3).and_return(item3)
    end

    it 'tracks success/failure' do
      job.perform_now

      expect(bulk_action.druid_count_success).to eq(2)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_total).to eq(3)

      expect(log).to have_received(:puts).with(/Failed NoMethodError .+ for #{druid3}/).once
    end
  end

  context 'when missing druid is included' do
    before do
      allow(Sdr::Repository).to receive(:find).with(druid: druid3).and_raise(Sdr::Repository::NotFoundResponse)
    end

    it 'tracks success/failure' do
      job.perform_now

      expect(bulk_action.druid_count_success).to eq(2)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_total).to eq(3)

      expect(log).to have_received(:puts).with(/Could not find object for #{druid3}/).once
    end
  end

  context 'when malformed druid is included' do
    let(:response) { instance_double(Faraday::Response, status: 400, body: nil, reason_phrase: "#/components/schemas/Druid pattern ^druid:[b-df-hjkmnp-tv-z]{2}[0-9]{3}[b-df-hjkmnp-tv-z]{2}[0-9]{4}$ does not match value: \"#{druid3}\", example: druid:bc123df4567") }

    before do
      allow(Sdr::Repository).to receive(:find).with(druid: druid3).and_raise(Dor::Services::Client::BadRequestError.new(response:))
    end

    it 'tracks success/failure' do
      job.perform_now
      expect(bulk_action.druid_count_success).to eq(2)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_total).to eq(3)

      expect(log).to have_received(:puts).with(/Could not request object for #{druid3}/).once
    end
  end
end
# rubocop:enable RSpec/IndexedLet
