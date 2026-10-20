# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::StructureForm do
  let(:mount_directory) { Dir.mktmpdir(nil, Rails.root.join('tmp')) }
  let(:multi_item_deposit_action) do
    create(:multi_item_deposit_action, mount_path: mount_directory, **model_attributes)
  end
  let(:model_attributes) { {} }
  let(:csv_header) { 'druid,sequence,filename,publish,preserve,rights_view,rights_download,rights_location' }
  let(:csv_string) { "#{csv_header}\nbc123df4567,1,file1.tif,yes,yes,world,world,\n" }
  let(:normalized_csv_string) { "#{csv_header}\ndruid:bc123df4567,1,file1.tif,yes,yes,world,world,\n" }
  let(:csv_tempfile) { Tempfile.new(['structural', '.csv']).tap { |file| file.write(csv_string) && file.flush } }
  let(:csv_file) { Rack::Test::UploadedFile.new(csv_tempfile.path, 'text/csv') }

  after do
    FileUtils.rm_rf(mount_directory)
  end

  def build_form(**attributes)
    described_class.new(attributes).tap { |form| form.multi_item_deposit_action = multi_item_deposit_action }
  end

  def write_mount_csv(content = csv_string)
    File.write(File.join(mount_directory, 'structural_metadata.csv'), content)
  end

  describe 'OCR validations' do
    it 'requires OCR languages when running OCR' do
      form = described_class.new(run_ocr: true, text_extraction_languages: [])

      expect(form).not_to be_valid
      expect(form.errors[:text_extraction_languages]).to be_present
    end

    it 'does not require OCR languages when not running OCR' do
      expect(described_class.new(run_ocr: false, text_extraction_languages: [])).to be_valid
    end
  end

  describe '.from_model' do
    subject(:form) { described_class.from_model(multi_item_deposit_action) }

    context 'with saved settings' do
      let(:model_attributes) do
        { perform_ocr: true, ocr_languages: ['English'], publish_preserve_all: true }
      end

      it 'prefills the OCR and publish / preserve settings' do
        expect(form).to have_attributes(run_ocr: true, text_extraction_languages: ['English'],
                                        publish_preserve_all: true)
      end
    end

    context 'when nothing has been saved' do
      it 'defaults to no structural metadata CSV' do
        expect(form).to have_attributes(structural_metadata_csv_choice: 'none', publish_preserve_all: false)
      end
    end

    context 'when a CSV is on the mount' do
      before { write_mount_csv }

      it 'defaults to the mount CSV' do
        expect(form.structural_metadata_csv_choice).to eq('mount')
      end
    end

    context 'when a CSV is required' do
      before { create(:item_deposit_action, multi_item_deposit_action:, content_type: 'media') }

      it 'defaults to uploading a CSV' do
        expect(form.structural_metadata_csv_choice).to eq('upload')
      end
    end

    context 'when a CSV was uploaded' do
      let(:model_attributes) { { structural_metadata_csv: csv_string, structural_metadata_csv_source: 'upload' } }

      before { write_mount_csv }

      it 'defaults to the uploaded CSV' do
        expect(form).to have_attributes(structural_metadata_csv_choice: 'upload', structural_metadata_csv: csv_string)
      end
    end

    context 'when a mount CSV was saved but is no longer on the mount' do
      let(:model_attributes) { { structural_metadata_csv: csv_string, structural_metadata_csv_source: 'mount' } }

      it 'defaults as if nothing had been saved' do
        expect(form).to have_attributes(structural_metadata_csv_choice: 'none', structural_metadata_csv: nil)
      end
    end

    context 'when the structure was built without a CSV' do
      let(:model_attributes) { { structuring_started_at: 1.hour.ago } }

      before { write_mount_csv }

      it 'keeps no structural metadata CSV' do
        expect(form.structural_metadata_csv_choice).to eq('none')
      end
    end
  end

  describe 'structural metadata CSV validations' do
    context 'when uploading a CSV' do
      it 'is valid' do
        expect(build_form(structural_metadata_csv_choice: 'upload', structural_metadata_csv_file: csv_file)).to be_valid
      end
    end

    context 'when uploading without a file' do
      it 'requires a file' do
        form = build_form(structural_metadata_csv_choice: 'upload')

        expect(form).not_to be_valid
        expect(form.errors[:structural_metadata_csv_file]).to eq(["can't be blank"])
      end
    end

    context 'when uploading without a file after an earlier upload' do
      it 'is valid' do
        expect(build_form(structural_metadata_csv_choice: 'upload', structural_metadata_csv: csv_string)).to be_valid
      end
    end

    context 'when the uploaded CSV is missing columns' do
      let(:csv_string) { "druid,sequence\nbc123df4567,1\n" }

      it 'reports the missing columns' do
        form = build_form(structural_metadata_csv_choice: 'upload', structural_metadata_csv_file: csv_file)

        expect(form).not_to be_valid
        expect(form.errors[:structural_metadata_csv_file].sole).to start_with('missing headers: filename')
      end
    end

    context 'when the uploaded file cannot be read' do
      let(:csv_tempfile) { Tempfile.new(['structural', '.txt']).tap { |file| file.write(csv_string) && file.flush } }

      it 'reports the error' do
        form = build_form(structural_metadata_csv_choice: 'upload', structural_metadata_csv_file: csv_file)

        expect(form).not_to be_valid
        expect(form.errors[:structural_metadata_csv_file]).to eq(['Unsupported upload file type'])
      end
    end

    context 'when using the mount CSV' do
      before { write_mount_csv }

      it 'is valid' do
        expect(build_form(structural_metadata_csv_choice: 'mount')).to be_valid
      end
    end

    context 'when the mount CSV is missing columns' do
      before { write_mount_csv("druid\nbc123df4567\n") }

      it 'reports the missing columns on the choice' do
        form = build_form(structural_metadata_csv_choice: 'mount')

        expect(form).not_to be_valid
        expect(form.errors[:structural_metadata_csv_choice].sole).to start_with('missing headers: sequence')
      end
    end

    context 'when the mount CSV is not found' do
      it 'reports that it was not found' do
        form = build_form(structural_metadata_csv_choice: 'mount')

        expect(form).not_to be_valid
        expect(form.errors[:structural_metadata_csv_choice])
          .to eq(['structural_metadata.csv not found in the mount path'])
      end
    end

    context 'when choosing no CSV but one is required' do
      before { create(:item_deposit_action, multi_item_deposit_action:, content_type: 'media') }

      it 'requires a CSV' do
        form = build_form(structural_metadata_csv_choice: 'none')

        expect(form).not_to be_valid
        expect(form.errors[:structural_metadata_csv_choice])
          .to eq(['A structural metadata CSV is required for media items'])
      end
    end

    context 'when the choice is not valid' do
      it 'is invalid' do
        expect(build_form(structural_metadata_csv_choice: 'other')).not_to be_valid
      end
    end
  end

  describe '#multi_item_deposit_action_attributes' do
    context 'when uploading a CSV' do
      it 'includes the normalized CSV' do
        form = build_form(run_ocr: true, text_extraction_languages: ['', 'English'], publish_preserve_all: true,
                          structural_metadata_csv_choice: 'upload', structural_metadata_csv_file: csv_file)

        expect(form.multi_item_deposit_action_attributes)
          .to eq(perform_ocr: true, ocr_languages: ['English'], structural_metadata_csv: normalized_csv_string,
                 structural_metadata_csv_source: 'upload', publish_preserve_all: false)
      end
    end

    context 'when using the mount CSV' do
      before { write_mount_csv }

      it 'includes the CSV read from the mount' do
        expect(build_form(structural_metadata_csv_choice: 'mount').multi_item_deposit_action_attributes)
          .to include(structural_metadata_csv: normalized_csv_string, structural_metadata_csv_source: 'mount',
                      publish_preserve_all: false)
      end
    end

    context 'when not using a CSV' do
      it 'clears the CSV and includes the publish / preserve setting' do
        form = build_form(structural_metadata_csv_choice: 'none', publish_preserve_all: true,
                          structural_metadata_csv: csv_string)

        expect(form.multi_item_deposit_action_attributes)
          .to eq(perform_ocr: false, ocr_languages: [], structural_metadata_csv: nil,
                 structural_metadata_csv_source: nil, publish_preserve_all: true)
      end
    end
  end

  describe '#unsaved_structural_metadata_csv?' do
    it 'is true for a new upload' do
      form = build_form(structural_metadata_csv_choice: 'upload', structural_metadata_csv_file: csv_file)

      expect(form).to be_unsaved_structural_metadata_csv
    end

    context 'when the upload is saved' do
      let(:model_attributes) { { structural_metadata_csv: csv_string, structural_metadata_csv_source: 'upload' } }

      it 'is false' do
        form = build_form(structural_metadata_csv_choice: 'upload', structural_metadata_csv: csv_string)

        expect(form).not_to be_unsaved_structural_metadata_csv
      end
    end
  end
end
