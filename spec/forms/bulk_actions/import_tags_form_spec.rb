# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::ImportTagsForm do
  subject(:form) { described_class.new(params) }

  let(:params) { { csv_file: Rack::Test::UploadedFile.new(tempfile.path, 'text/csv') } }
  let(:tempfile) { Tempfile.new(['upload', '.csv']).tap { |file| file.write(csv) && file.flush } }

  describe 'validations' do
    context 'when the rows are valid' do
      let(:csv) { "bc123df4567, Project : Testing ,Test Tag : Testing 2\nDRUID:fg456hj7890,\n\n" }

      it 'is valid and normalizes the rows' do
        expect(form.valid?).to be true
        expect(form.normalized_csv_file).to eq(
          "druid:bc123df4567,Project : Testing,Test Tag : Testing 2\ndruid:fg456hj7890\n"
        )
      end
    end

    context 'when there are no rows' do
      let(:csv) { "\n" }

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(['has no rows'])
      end
    end

    context 'when a row has an invalid druid' do
      let(:csv) { "notadruid,Project : Testing\n" }

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(['row 1: invalid druid: notadruid'])
      end
    end

    context 'when a row has a blank druid' do
      let(:csv) { ",Project : Testing\n" }

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(['row 1: invalid druid: Project : Testing'])
      end
    end

    context 'when a row has invalid tags' do
      let(:csv) { "bc123df4567,Project : Testing,Testing,Test:Tag\n" }

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(['row 1: invalid tags: Testing, Test:Tag'])
      end
    end

    context 'when a druid is in more than one row' do
      let(:csv) { "bc123df4567,Project : Testing\ndruid:bc123df4567,Project : Other\n" }

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(['druid:bc123df4567 is in more than one row'])
      end
    end
  end
end
