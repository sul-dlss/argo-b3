# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::TechnicalMetadataComponent, type: :component do
  let(:technical_metadata) do
    {
      'druid' => 'druid:bc123df4567',
      'filename' => 'folder1/image1.tif',
      'mimetype' => 'image/tiff',
      'bytes' => 2048,
      'file_modification' => '2026-01-15T18:30:00.000Z',
      'image_metadata' => { 'width' => 800 }
    }
  end

  it 'renders the formatted technical metadata, excluding the druid and filename' do
    render_inline(described_class.new(technical_metadata:))

    expect(page).to have_css('dt + dd', text: 'image/tiff')
    expect(page).to have_css('dt', text: 'Bytes')
    expect(page).to have_css('dt + dd', text: '2 KB')
    expect(page).to have_css('dt', text: 'File modification')
    expect(page).to have_css('dt + dd', text: '2026-01-15 10:30:00 PT')
    expect(page).to have_css('dd dl dt', text: 'Width')
    expect(page).to have_no_css('dt', text: 'Druid')
    expect(page).to have_no_css('dt', text: 'Filename')
  end
end
