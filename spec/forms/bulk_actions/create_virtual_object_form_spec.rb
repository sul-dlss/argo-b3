# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::CreateVirtualObjectForm do
  subject(:form) { described_class.new(params) }

  let(:params) { { csv_file: Rack::Test::UploadedFile.new(tempfile.path, 'text/csv') } }
  let(:tempfile) { Tempfile.new(['upload', '.csv']).tap { |file| file.write(csv) && file.flush } }

  describe 'validations' do
    context 'when the rows are valid' do
      let(:csv) { "bc123df4567,druid:cd234fg5678,DRUID:df345gh6789\nDruid:fg456hj7890,hj567km8901\n" }

      it 'is valid and normalizes the druid prefixes' do
        expect(form.valid?).to be true
        expect(form.normalized_csv_file).to eq(
          "druid:bc123df4567,druid:cd234fg5678,druid:df345gh6789\ndruid:fg456hj7890,druid:hj567km8901\n"
        )
      end
    end

    %w[xlsx ods].each do |extension|
      context "when the csv_file is an #{extension} spreadsheet" do
        let(:params) { { csv_file: fixture_file_upload("create_virtual_object.#{extension}") } }

        it 'is valid and prefixes the druids' do
          expect(form.valid?).to be true
          expect(form.normalized_csv_file).to eq(
            "druid:bc123df4567,druid:cd234fg5678,druid:df345gh6789\ndruid:fg456hj7890,druid:hj567km8901\n"
          )
        end
      end
    end

    context 'when a row has an invalid druid' do
      let(:csv) { "bc123df4567,notadruid,cd234fg5678\n" }

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(['row 1: invalid druids: notadruid'])
      end
    end

    context 'when a header row is included' do
      let(:csv) { "druid,constituent\nbc123df4567,cd234fg5678\n" }

      it 'is invalid and reports the druids as entered' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(['row 1: invalid druids: druid, constituent'])
      end
    end

    context 'when a row has no constituents' do
      let(:csv) { "bc123df4567,cd234fg5678\nfg456hj7890\n" }

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(['row 2: no constituent druids'])
      end
    end

    context 'when a virtual object is its own constituent' do
      let(:csv) { "bc123df4567,cd234fg5678,druid:bc123df4567\n" }

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(['row 1: druid:bc123df4567 cannot be a constituent of itself'])
      end
    end

    context 'when a virtual object is in more than one row' do
      let(:csv) { "bc123df4567,cd234fg5678\ndruid:bc123df4567,fg456hj7890\n" }

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(['druid:bc123df4567 is the virtual object in more than one row'])
      end
    end

    context 'when the csv_file has no rows' do
      let(:csv) { ",,\n" }

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(['has no rows'])
      end
    end

    context 'when the csv_file cannot be read' do
      let(:csv) { "bc123df4567,cd234fg5678\n\xFF\xFE\n" }

      it 'is invalid' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(['CSV contains invalid UTF-8 bytes on line 2.'])
      end
    end
  end
end
