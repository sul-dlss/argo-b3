# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::RegisterJob do
  subject(:job) { described_class.new(bulk_action:, **params) }

  let(:params) { { csv_file: csv_string } }

  let(:bulk_action) { create(:bulk_action, action_type: 'register') }
  let(:log) { instance_double(File, puts: nil, close: true) }
  let(:user_name) { bulk_action.user.sunetid }

  let(:cocina_object) do
    build(:dro_with_metadata, id: 'druid:df123df4567', label: 'My object')
      .new(identification: {
             barcode: '36105010101010',
             catalogLinks: [{ catalog: 'folio',
                              catalogRecordId: 'in12345', refresh: true }],
             sourceId: 'foo:bar1'
           })
  end

  let(:csv_string) do
    <<~CSV
      administrative_policy_object,collection,initial_workflow,content_type,source_id,label,rights_view,rights_download,tags,tags
      druid:bc123df4567,druid:bk024qs1808,accessionWF,book,foo:123,My new object,world,world,csv : test,Project : two
      druid:dj123qx4567,druid:bk024qs1808,accessionWF,book,foo:123,A label,world,world
    CSV
  end

  before do
    allow(Sdr::Repository).to receive(:register).and_return(cocina_object)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
  end

  after do
    bulk_action.remove_output_directory!
  end

  context 'when parsing fails' do
    let(:csv_string) do
      <<~CSV
        administrative_policy_object,initial_workflow,content_type,source_id,label,rights_view,rights_download
        druid:123,accessionWF,book,foo:123,My new object,world,world
      CSV
    end

    it 'does not register the object' do
      job.perform_now

      expect(Sdr::Repository).not_to have_received(:register)
      expect(log).to have_received(:puts)
        .with(/.*does not match pattern:\s+\^druid:\[b-df-hjkmnp-tv-z\]\{2\}\[0-9\]\{3\}\[b-df-hjkmnp-tv-z\]\{2\}\[0-9\]\{4\}\$/) # rubocop:disable Layout/LineLength
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1
    end
  end

  context 'when registration fails' do
    let(:csv_string) do
      <<~CSV
        administrative_policy_object,initial_workflow,content_type,source_id,label,rights_view,rights_download,tags,tags
        druid:bc123df4567,accessionWF,book,foo:123,My new object,world,world,csv : test,Project : two
      CSV
    end

    before do
      allow(Sdr::Repository).to receive(:register).and_raise(StandardError, 'connection problem')
    end

    it 'logs the error' do
      job.perform_now

      expect(log).to have_received(:puts).with(/connection problem/)
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1
    end
  end

  context 'when registration is successful' do
    let(:csv_filepath) { "#{bulk_action.output_directory}/registration_report.csv" }

    it 'registers the object' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:register)
        .with(cocina_object: Cocina::Models::RequestDRO,
              tags: ['csv : test', 'Project : two'],
              workflow_name: 'accessionWF',
              user_name:)
      expect(Sdr::Repository).to have_received(:register)
        .with(cocina_object: Cocina::Models::RequestDRO,
              tags: [],
              workflow_name: 'accessionWF',
              user_name:)
      expect(log).to have_received(:puts).with(/Registration successful for druid:df123df4567/).twice
      expect(bulk_action.druid_count_success).to eq 2
      expect(File.read(csv_filepath)).to eq("Druid,Barcode,Folio Instance HRID,Source Id,Label\ndf123df4567,36105010101010,in12345,foo:bar1,My object\ndf123df4567,36105010101010,in12345,foo:bar1,My object\n") # rubocop:disable Layout/LineLength
    end
  end

  context 'when registration is successful with params' do
    # Params are provided from registration page (not bulk action page)
    let(:csv_string) do
      <<~CSV
        source_id,label
        foo:123,My new object
        foo:123,A label
      CSV
    end

    let(:params) do
      {
        csv_file: csv_string,
        administrative_policy_object: 'druid:bc123df4567',
        collection: 'druid:bk024qs1808',
        initial_workflow: 'accessionWF',
        content_type: 'book',
        rights_view: 'world',
        rights_download: 'world',
        tags: ['csv : test', 'Project : two']
      }
    end

    it 'registers the object' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:register)
        .with(cocina_object: Cocina::Models::RequestDRO,
              tags: ['csv : test', 'Project : two'],
              workflow_name: 'accessionWF',
              user_name:).twice
      expect(log).to have_received(:puts).with(/Registration successful for druid:df123df4567/).twice
      expect(bulk_action.druid_count_success).to eq 2
    end
  end

  context 'with valid view:stanford, download:none, and rights_controlledDigitalLending:true' do
    let(:csv_string) do
      <<~CSV
        administrative_policy_object,collection,initial_workflow,content_type,source_id,label,rights_view,rights_download,rights_controlledDigitalLending,tags,tags
        druid:bc123df4567,druid:bk024qs1808,accessionWF,book,foo:123,My new object,stanford,none,true,csv : test,Project : two
        druid:dj123qx4567,druid:bk024qs1808,accessionWF,book,foo:123,A label,stanford,none,true
      CSV
    end

    it 'registers the objects' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:register)
        .with(cocina_object: Cocina::Models::RequestDRO,
              tags: ['csv : test', 'Project : two'],
              workflow_name: 'accessionWF',
              user_name:)
      expect(Sdr::Repository).to have_received(:register)
        .with(cocina_object: Cocina::Models::RequestDRO,
              tags: [],
              workflow_name: 'accessionWF',
              user_name:)
      expect(log).to have_received(:puts).with(/Registration successful for druid:df123df4567/).twice
      expect(bulk_action.druid_count_success).to eq 2
    end
  end
end
