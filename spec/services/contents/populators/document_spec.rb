# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::Populators::Document do
  subject(:structure) { described_class.structure(content:, cocina_object:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let(:cocina_object) do
    build(:dro_with_metadata, id: content.druid).new(access: { view: 'world', download: 'world' })
  end

  describe '.disqualifying_reasons' do
    subject(:reasons) { described_class.disqualifying_reasons(content:, cocina_object:) }

    context 'when there is a PDF' do
      before do
        create(:content_file_binary, content:, filepath: 'folder/report.pdf', mime_type: 'application/pdf')
        create(:content_file_binary, content:, filepath: 'data.csv', mime_type: 'text/csv')
      end

      it 'has no reasons' do
        expect(reasons).to eq([])
      end
    end

    context 'when there are no PDFs' do
      before do
        create(:content_file_binary, content:, filepath: 'data.csv', mime_type: 'text/csv')
      end

      it 'has the no PDFs reason' do
        expect(reasons).to eq([:no_pdfs])
      end
    end
  end

  describe '.structure' do
    context 'when there is a PDF' do
      let!(:pdf_binary) do
        create(:content_file_binary, content:, filepath: 'report.pdf', mime_type: 'application/pdf')
      end

      it 'creates a document file set with a file for the PDF' do
        structure

        expect(content.content_file_sets.sole).to have_attributes(file_set_type: 'document', label: 'Document 1')
        content_file = content.content_files.sole
        expect(content_file.content_file_binary).to eq(pdf_binary)
        expect(content_file).to have_attributes(label: 'report.pdf', preserve: true, shelve: true, publish: true,
                                                use: nil,
                                                view: cocina_object.access.view,
                                                download: cocina_object.access.download,
                                                location: cocina_object.access.location)
      end
    end

    context 'when there are PDFs and other files' do
      before do
        # Sorts before the PDFs by path, but is placed after them because it is not a PDF.
        create(:content_file_binary, content:, filepath: 'aaa_data.csv', mime_type: 'text/csv')
        create(:content_file_binary, content:, filepath: 'report10.pdf', mime_type: 'application/pdf')
        create(:content_file_binary, content:, filepath: 'report2.pdf', mime_type: 'application/pdf')
        create(:content_file_binary, content:, filepath: 'image.tif', mime_type: 'image/tiff')
      end

      it 'creates a file set per file, with the documents first, each in path order' do
        structure

        expect(content.content_file_sets.map { |file_set| [file_set.file_set_type, file_set.label] })
          .to eq([['document', 'Document 1'], ['document', 'Document 2'], ['file', 'File 1'], ['file', 'File 2']])
        expect(content.content_file_sets.pluck(:position)).to eq([1, 2, 3, 4])
        expect(content.content_files.map(&:filepath)).to eq(%w[report2.pdf report10.pdf aaa_data.csv image.tif])
      end

      it 'uses the attributes for the mime type of each file' do
        structure

        expect(content.content_files.find_by(label: 'image.tif'))
          .to have_attributes(preserve: true, shelve: false, publish: false)
      end
    end

    context 'when the object is dark' do
      let(:cocina_object) do
        build(:dro_with_metadata, id: content.druid).new(access: { view: 'dark', download: 'none' })
      end

      before do
        create(:content_file_binary, content:, filepath: 'report.pdf', mime_type: 'application/pdf')
      end

      it 'preserves but does not shelve or publish the files' do
        structure

        expect(content.content_files.sole).to have_attributes(preserve: true, shelve: false, publish: false,
                                                              view: 'dark')
      end
    end

    context 'when the object is embargoed' do
      let(:cocina_object) do
        build(:dro_with_metadata, id: content.druid).new(
          access: {
            view: 'citation-only',
            download: 'none',
            embargo: {
              releaseDate: DateTime.parse('2040-06-15T19:00:00Z'),
              view: 'stanford',
              download: 'stanford'
            }
          }
        )
      end

      before do
        create(:content_file_binary, content:, filepath: 'report.pdf', mime_type: 'application/pdf')
      end

      it 'uses the embargo access settings' do
        structure

        expect(content.content_files.sole).to have_attributes(view: 'stanford', download: 'stanford')
      end
    end
  end

  describe '.append' do
    subject(:append) { described_class.append(content:, cocina_object:) }

    let(:existing_document_file_set) do
      create(:content_file_set, content:, file_set_type: 'document', label: 'Document 1', position: 1)
    end
    let(:existing_file_file_set) do
      create(:content_file_set, content:, file_set_type: 'file', label: 'File 1', position: 2)
    end
    let!(:existing_content_file) do
      create(:content_file, content_file_set: existing_document_file_set,
                            content_file_binary: create(:content_file_binary, content:, filepath: 'report1.pdf',
                                                                              mime_type: 'application/pdf'),
                            label: 'report1.pdf')
    end

    before do
      create(:content_file, content_file_set: existing_file_file_set,
                            content_file_binary: create(:content_file_binary, content:, filepath: 'data1.csv',
                                                                              mime_type: 'text/csv'),
                            label: 'data1.csv')
      create(:content_file_binary, content:, filepath: 'data2.csv', mime_type: 'text/csv')
      create(:content_file_binary, content:, filepath: 'report2.pdf', mime_type: 'application/pdf')
    end

    it 'creates file sets at the end, with the documents first, continuing the label numbering' do
      append

      expect(content.content_file_sets.map(&:label)).to eq(['Document 1', 'File 1', 'Document 2', 'File 2'])
      expect(content.content_file_sets.pluck(:position)).to eq([1, 2, 3, 4])
      expect(content.content_files.map(&:filepath)).to eq(%w[report1.pdf data1.csv report2.pdf data2.csv])
    end

    it 'retains the existing file sets and files' do
      append

      expect(existing_document_file_set.reload).to have_attributes(position: 1)
      expect(existing_document_file_set.content_files.sole).to eq(existing_content_file)
    end
  end
end
