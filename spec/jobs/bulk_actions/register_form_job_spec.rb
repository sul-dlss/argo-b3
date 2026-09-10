# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::RegisterFormJob do
  subject(:job) { described_class.new(bulk_action:, items_registration_form:) }

  let(:bulk_action) { create(:bulk_action, action_type: 'register_form') }
  let(:log) { instance_double(File, puts: nil, close: true) }
  let(:user_name) { bulk_action.user.sunetid }

  let(:items_registration_form) do
    ItemsRegistrationForm.new(
      apo_druid: 'druid:bc123df4567',
      content_type: Cocina::Models::ObjectType.book,
      access_view: 'world',
      access_download: 'world',
      item_registrations_attributes: [
        { source_id: 'sul:1234', title: 'A title' },
        { source_id: 'sul:5678', barcode: '36105212345678', catalog_record_id: 'in11403803' }
      ]
    )
  end

  let(:first_cocina_object) do
    build(:dro_with_metadata, id: 'druid:bc123df4567', title: 'A title')
      .new(identification: { sourceId: 'sul:1234' })
  end

  let(:second_cocina_object) do
    build(:dro_with_metadata, id: 'druid:dj123qx4568', title: 'Another title')
      .new(identification: {
             barcode: '36105212345678',
             catalogLinks: [{ catalog: 'folio', catalogRecordId: 'in11403803', refresh: true }],
             sourceId: 'sul:5678'
           })
  end

  let(:csv_filepath) { "#{bulk_action.output_directory}/registration_report.csv" }

  before do
    allow(Sdr::Repository).to receive(:register).and_return(first_cocina_object, second_cocina_object)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(bulk_action.log_filepath, 'a').and_return(log)
  end

  after do
    bulk_action.remove_output_directory!
  end

  context 'when registration is successful' do
    it 'registers the objects' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:register)
        .with(request_cocina_object: Cocina::Models::RequestDRO, user_name:).twice
      expect(log).to have_received(:puts).with(/druid:bc123df4567\tSuccess: Registration successful/)
      expect(log).to have_received(:puts).with(/druid:dj123qx4568\tSuccess: Registration successful/)
      expect(bulk_action.druid_count_total).to eq 2
      expect(bulk_action.druid_count_success).to eq 2
      expect(bulk_action.druid_count_fail).to eq 0
    end

    it 'builds the request from the form' do
      job.perform_now

      request_cocina_objects = []
      expect(Sdr::Repository).to have_received(:register).twice do |request_cocina_object:, **|
        request_cocina_objects << request_cocina_object
      end

      first_request, second_request = request_cocina_objects
      expect(first_request.type).to eq Cocina::Models::ObjectType.book
      expect(first_request.administrative.hasAdminPolicy).to eq 'druid:bc123df4567'
      expect(first_request.identification.sourceId).to eq 'sul:1234'
      expect(first_request.identification.barcode).to be_nil
      expect(first_request.description.title.first.value).to eq 'A title'
      expect(first_request.access.view).to eq 'world'
      expect(first_request.access.download).to eq 'world'

      expect(second_request.identification.sourceId).to eq 'sul:5678'
      expect(second_request.identification.barcode).to eq '36105212345678'
      expect(second_request.identification.catalogLinks.first.to_h)
        .to include(catalog: 'folio', catalogRecordId: 'in11403803', refresh: true)
    end

    it 'writes the registration report' do
      job.perform_now

      expect(File.read(csv_filepath)).to eq(
        "Druid,Barcode,Folio Instance HRID,Source Id,Title\n" \
        "bc123df4567,,,sul:1234,A title\n" \
        "dj123qx4568,36105212345678,in11403803,sul:5678,Another title\n"
      )
    end
  end

  context 'when registration fails' do
    before do
      allow(Sdr::Repository).to receive(:register).and_raise(StandardError, 'connection problem')
    end

    it 'logs the errors' do
      job.perform_now

      expect(log).to have_received(:puts).with(/line 1\t\tError: StandardError connection problem/)
      expect(log).to have_received(:puts).with(/line 2\t\tError: StandardError connection problem/)
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 2
      expect(File.read(csv_filepath)).to eq("Druid,Barcode,Folio Instance HRID,Source Id,Title\n")
    end
  end

  context 'when an item is invalid' do
    let(:items_registration_form) do
      ItemsRegistrationForm.new(
        apo_druid: 'druid:bc123df4567',
        content_type: Cocina::Models::ObjectType.book,
        access_view: 'world',
        access_download: 'world',
        item_registrations_attributes: [
          { source_id: 'not a source id', title: 'A title' },
          { source_id: 'sul:1234', title: 'A title' }
        ]
      )
    end

    it 'registers the valid item and logs a failure for the invalid item' do
      job.perform_now

      expect(Sdr::Repository).to have_received(:register).once
      expect(log).to have_received(:puts).with(/line 1\t\tError: ActiveModel::ValidationError/)
      expect(bulk_action.druid_count_success).to eq 1
      expect(bulk_action.druid_count_fail).to eq 1
    end
  end
end
