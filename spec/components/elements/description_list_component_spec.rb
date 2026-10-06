# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::DescriptionListComponent, type: :component do
  let(:hash) do
    {
      'filename' => 'folder1/image1.tif',
      'bytes' => 1024,
      'pdf_metadata' => nil,
      'dro_file_parts' => [],
      'image_metadata' => { 'width' => 800, 'height' => 600 },
      'tags' => %w[first second]
    }
  end

  it 'renders the hash as a description list with nested description lists' do
    render_inline(described_class.new(hash:))

    expect(page).to have_css('dl.row > dt.col-sm-3.col-lg-2', text: 'Filename')
    expect(page).to have_css('dl.row > dt.col-sm-3.col-lg-2 + dd.col-sm-9.col-lg-10', text: 'folder1/image1.tif')
    expect(page).to have_css('dl.row > dt.col-sm-3.col-lg-2', text: 'Bytes')
    expect(page).to have_css('dl.row > dt.col-sm-3.col-lg-2', text: 'Image metadata')
    expect(page).to have_css('dd.col-sm-9.col-lg-10 > dl.row > dt.col-sm-4.col-lg-2', text: 'Width')
    expect(page).to have_css('dd.col-sm-9.col-lg-10 > dl.row > dd.col-sm-8.col-lg-10', text: '800')
    expect(page).to have_css('dd.col-sm-9.col-lg-10 > dl.row > dt.col-sm-4.col-lg-2', text: 'Height')
    expect(page).to have_css('dd.col-sm-9.col-lg-10 > div', text: 'first')
    expect(page).to have_css('dd.col-sm-9.col-lg-10 > div', text: 'second')
  end

  it 'omits nil and empty values' do
    render_inline(described_class.new(hash:))

    expect(page).to have_no_css('dt', text: 'Pdf metadata')
    expect(page).to have_no_css('dt', text: 'Dro file parts')
  end

  context 'when the value is an array of hashes' do
    let(:hash) { { 'dro_file_parts' => [{ 'part_type' => 'audio' }, { 'part_type' => 'video' }] } }

    it 'renders a nested description list for each hash' do
      render_inline(described_class.new(hash:))

      expect(page).to have_css('dd.col-sm-9.col-lg-10 > dl.row', count: 2)
      expect(page).to have_css('dd.col-sm-9.col-lg-10 > dl.row:nth-of-type(1) > dd.col-sm-8.col-lg-10', text: 'audio')
      expect(page).to have_css('dd.col-sm-9.col-lg-10 > dl.row:nth-of-type(2) > dd.col-sm-8.col-lg-10', text: 'video')
    end
  end
end
