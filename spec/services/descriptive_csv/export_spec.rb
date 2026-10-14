# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptiveCsv::Export do
  subject(:run) { described_class.export(source_id:, description:) }

  let(:source_id) { 'sul:123' }
  let(:description) do
    Cocina::Models::Description.new(
      { title: [{ value: 'Stored title' }], purl: 'https://purl.stanford.edu/zt570qh4444' }
    )
  end

  it 'rectangularizes the item' do
    expect(run).to eq('source_id' => 'sul:123', 'title1.value' => 'Stored title', 'purl' => 'https://purl.stanford.edu/zt570qh4444')
  end

  describe '.as_csv' do
    subject(:csv) { CSV.parse(described_class.as_csv(descriptions:), headers: true) }

    let(:descriptions) do
      {
        'druid:bc123df4567' => { 'source_id' => 'sul:1', 'title1.value' => 'First' },
        'druid:bd123fg5678' => { 'source_id' => 'sul:2', 'title1.value' => 'Second', 'purl' => 'https://purl.stanford.edu/bd123fg5678' }
      }
    end

    it 'writes one row per druid with a bare druid and the merged headers' do
      expect(csv.headers).to eq %w[druid source_id title1.value purl]
      expect(csv.map(&:to_h)).to eq [
        { 'druid' => 'bc123df4567', 'source_id' => 'sul:1', 'title1.value' => 'First', 'purl' => nil },
        { 'druid' => 'bd123fg5678', 'source_id' => 'sul:2', 'title1.value' => 'Second',
          'purl' => 'https://purl.stanford.edu/bd123fg5678' }
      ]
    end
  end
end
