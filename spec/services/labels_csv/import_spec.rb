# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabelsCsv::Import do
  subject(:result) { described_class.call(rows:, content:) }

  let(:content) { create(:content, :mutable, druid: 'druid:bc123df4567') }
  let(:rows) { CSV.parse(csv_string, headers: true).each.with_index(2).map { |row, number| [number, row] } }
  let(:labels) { content.content_file_sets.reload.map(&:label) }

  before do
    create(:content_file_set, content:, position: 1, label: 'Page 1')
    create(:content_file_set, content:, position: 2, label: 'Page 2')
    create(:content_file_set, content:, position: 3, label: 'Page 3')
  end

  context 'with rows for some of the resources' do
    let(:csv_string) do
      <<~CSV
        druid,sequence,resource_label
        druid:bc123df4567,3,Back cover
        druid:bc123df4567,1,Cover
      CSV
    end

    it 'updates the labels of those resources, leaving the others unchanged' do
      expect(result).to be_success
      expect(labels).to eq(['Cover', 'Page 2', 'Back cover'])
    end
  end

  context 'with a blank label' do
    let(:csv_string) { "druid,sequence,resource_label\ndruid:bc123df4567,2,\n" }

    it 'clears the label' do
      expect(result).to be_success
      expect(labels).to eq(['Page 1', '', 'Page 3'])
    end
  end

  context 'with a sequence past the last resource' do
    let(:csv_string) { "druid,sequence,resource_label\ndruid:bc123df4567,1,Cover\ndruid:bc123df4567,4,Extra\n" }

    it 'ignores the row' do
      expect(result).to be_success
      expect(labels).to eq(['Cover', 'Page 2', 'Page 3'])
    end
  end

  context 'with an entirely blank row' do
    let(:csv_string) { "druid,sequence,resource_label\ndruid:bc123df4567,,\ndruid:bc123df4567,1,Cover\n" }

    it 'ignores the row' do
      expect(result).to be_success
      expect(labels).to eq(['Cover', 'Page 2', 'Page 3'])
    end
  end

  context 'with missing columns' do
    let(:csv_string) { "druid,label\ndruid:bc123df4567,Cover\n" }

    it 'fails with only the missing columns, without changing labels' do
      expect(result.failure).to eq([StructuralCsv::ValidationError.new(1, 'Missing required column "sequence"'),
                                    StructuralCsv::ValidationError.new(1, 'Missing required column "resource_label"')])
      expect(labels).to eq(['Page 1', 'Page 2', 'Page 3'])
    end
  end

  context 'with no rows' do
    let(:csv_string) { "druid,sequence,resource_label\ndruid:bc123df4567,,\n" }

    it 'fails' do
      expect(result.failure).to eq([StructuralCsv::ValidationError.new(2, 'No labels to import')])
    end
  end

  context 'with invalid and repeated sequences' do
    let(:csv_string) do
      <<~CSV
        druid,sequence,resource_label
        druid:bc123df4567,1,Cover
        druid:bc123df4567,abc,Page
        druid:bc123df4567,0,Page
        druid:bc123df4567,,Page
        druid:bc123df4567,1,Front
      CSV
    end

    it 'fails with an error for each row, without changing labels' do
      expect(result.failure).to eq([StructuralCsv::ValidationError.new(3, 'Sequence "abc" is not a positive integer'),
                                    StructuralCsv::ValidationError.new(4, 'Sequence "0" is not a positive integer'),
                                    StructuralCsv::ValidationError.new(5, 'Sequence "" is not a positive integer'),
                                    StructuralCsv::ValidationError.new(6, 'Sequence 1 appears more than once')])
      expect(labels).to eq(['Page 1', 'Page 2', 'Page 3'])
    end
  end

  context 'when the content is immutable' do
    let(:content) { create(:content, druid: 'druid:bc123df4567') }
    let(:csv_string) { "druid,sequence,resource_label\n" }

    it 'raises' do
      expect { result }.to raise_error(ArgumentError, 'Content must be mutable')
    end
  end
end
