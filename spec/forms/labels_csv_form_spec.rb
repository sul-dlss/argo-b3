# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabelsCsvForm do
  subject(:form) { described_class.new(csv_file:) }

  let(:csv_file) { Rack::Test::UploadedFile.new(csv_tempfile.path, 'text/csv') }
  let(:csv_tempfile) { Tempfile.new(['labels', '.csv']).tap { |file| file.write(csv_string) && file.flush } }
  let(:content) { create(:content, :mutable, druid: 'druid:bc123df4567') }
  let(:content_file_set) { create(:content_file_set, content:, label: 'Page 1') }

  before { content_file_set }

  describe '#update_content' do
    context 'when the rows are valid' do
      let(:csv_string) { "druid,sequence,resource_label\nbc123df4567,1,Cover\n" }

      it 'updates the labels' do
        form.update_content(content:)

        expect(form.errors).to be_empty
        expect(content_file_set.reload.label).to eq('Cover')
      end
    end

    context 'when a row has a different druid' do
      let(:csv_string) { "druid,sequence,resource_label\nxy987wv6543,1,Cover\n" }

      it 'adds the error without updating the labels' do
        form.update_content(content:)

        expect(form.errors[:csv_file]).to eq(['Row 2: Druid druid:xy987wv6543 does not match this object'])
        expect(content_file_set.reload.label).to eq('Page 1')
      end
    end

    context 'when the import fails' do
      let(:csv_string) { "druid,sequence,resource_label\nbc123df4567,abc,Cover\n" }

      it 'adds the import errors' do
        form.update_content(content:)

        expect(form.errors[:csv_file]).to eq(['Row 2: Sequence "abc" is not a positive integer'])
      end
    end

    context 'when the CSV has only a header row that is missing columns' do
      let(:csv_string) { "druid,label\n" }

      it 'adds the missing columns error' do
        form.update_content(content:)

        expect(form.errors[:csv_file]).to eq(['Row 1: Missing required column "sequence"',
                                              'Row 1: Missing required column "resource_label"'])
      end
    end

    context 'when no file is uploaded' do
      let(:csv_file) { nil }
      let(:csv_string) { '' }

      it 'adds the error' do
        form.update_content(content:)

        expect(form.errors[:csv_file]).to eq(["can't be blank"])
      end
    end
  end
end
