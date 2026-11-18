# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabelsCsv::Export do
  subject(:csv) { described_class.as_csv(content:) }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }

  before do
    create(:content_file_set, content:, position: 2, label: 'Page 2')
    create(:content_file_set, content:, position: 1, label: 'Cover')
    create(:content_file_set, content:, position: 3, label: '')
  end

  it 'has a row for each resource in order, numbered by sequence' do
    expect(csv).to eq(<<~CSV)
      druid,sequence,resource_label
      bc123df4567,1,Cover
      bc123df4567,2,Page 2
      bc123df4567,3,""
    CSV
  end
end
