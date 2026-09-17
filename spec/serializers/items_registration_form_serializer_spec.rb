# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemsRegistrationFormSerializer do
  let(:form) do
    ItemsRegistrationForm.new(items_choice: ItemsRegistrationForm::UPLOAD_CSV_CHOICE, csv_file:)
  end

  let(:csv_file) { fixture_file_upload('register_multiple_items.csv', 'text/csv') }

  let(:expected_csv) do
    "barcode,folio_instance_hrid,source_id,title\n" \
      "36105212345678,in11403803,sul:first-item,First title\n" \
      "36105287654321,in11403804,sul:second-item,Second title\n"
  end

  it 'serializes the uploaded csv file as a normalized csv string' do
    serialized = described_class.serialize(form)

    expect(serialized[:attributes]).not_to have_key('csv_file')
    expect(serialized[:attributes]['csv']).to eq(expected_csv)
  end

  it 'serializes and deserializes an ItemsRegistrationForm' do
    serialized = described_class.serialize(form)
    # Change to JSON and back to simulate ActiveJob serialization.
    serialized = JSON.parse(serialized.to_json)
    deserialized = described_class.deserialize(serialized)

    expect(deserialized).to be_a(ItemsRegistrationForm)
    expect(deserialized.csv).to eq(expected_csv)
    expect(deserialized.csv_file).to be_nil
  end

  context 'when the form has an Excel file' do
    let(:csv_file) { fixture_file_upload('catalog_record_id_and_barcode.xlsx') }

    it 'normalizes the uploaded file to a csv string' do
      serialized = described_class.serialize(form)

      expect(serialized[:attributes]['csv']).to start_with('Druid,Catkey,Barcode')
    end
  end

  context 'when the form has already been serialized' do
    let(:form) do
      ItemsRegistrationForm.new(items_choice: ItemsRegistrationForm::UPLOAD_CSV_CHOICE, csv: expected_csv)
    end

    it 'retains the csv' do
      serialized = described_class.serialize(form)

      expect(serialized[:attributes]['csv']).to eq(expected_csv)
    end
  end

  context 'when not an ItemsRegistrationForm' do
    it 'does not serialize the object' do
      expect(described_class.serialize?(ResultsSearchForm.new)).to be(false)
    end
  end
end
