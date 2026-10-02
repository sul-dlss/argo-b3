# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StructuralCsvForm do
  subject(:form) { described_class.new(csv_file:) }

  let(:csv_file) { Rack::Test::UploadedFile.new(csv_tempfile.path, 'text/csv') }
  let(:csv_tempfile) { Tempfile.new(['structure', extension]).tap { |file| file.write(csv_string) && file.flush } }
  let(:extension) { '.csv' }
  let(:csv_string) { "druid,sequence,filename\nbc123df4567,1,page_0001.tif\n" }

  it 'numbers the rows from the first row after the header' do
    expect(form).to be_valid
    expect(form.numbered_rows.map(&:first)).to eq([2])
    expect(form.numbered_rows.first.last['druid']).to eq('druid:bc123df4567')
  end

  context 'when the file type is not supported' do
    let(:extension) { '.txt' }

    it 'is not valid' do
      expect(form).not_to be_valid
      expect(form.errors[:csv_file]).to eq(['Unsupported upload file type'])
    end
  end

  context 'when the CSV is malformed' do
    let(:csv_string) { "druid,sequence,filename\nbc123df4567,\"1,page_0001.tif\n" }

    it 'is not valid' do
      expect(form).not_to be_valid
      expect(form.errors[:csv_file]).to be_present
    end
  end

  describe '#add_validation_errors' do
    it 'adds the errors with their row numbers' do
      form.add_validation_errors([StructuralCsv::ValidationError.new(3, 'Bad value')])

      expect(form.errors[:csv_file]).to eq(['Row 3: Bad value'])
    end
  end
end
