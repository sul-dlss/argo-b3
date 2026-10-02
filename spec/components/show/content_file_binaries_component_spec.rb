# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ContentFileBinariesComponent, type: :component do
  let(:component) { described_class.new(content_record: content) }

  let(:content) { create(:content) }

  context 'when the content has file binaries' do
    before do
      create(:content_file_binary, content:, filepath: 'image2.tif', size: 2048, mime_type: 'image/tiff')
      create(:content_file_binary, content:, filepath: 'image1.tif', size: 1024, mime_type: 'image/tiff')
    end

    it 'renders a row for each file binary in path order' do
      render_inline(component)

      expect(page).to have_css("table.table-h3[aria-label='Files']")
      expect(page).to have_no_css('caption')
      expect(page).to have_css('th', text: 'File name')
      expect(page).to have_css('th', text: 'Size')
      expect(page).to have_css('th', text: 'Type')
      expect(page).to have_css('tbody tr:nth-child(1) th', text: 'image1.tif')
      expect(page).to have_css('tbody tr:nth-child(1) td', text: '1 KB')
      expect(page).to have_css('tbody tr:nth-child(1) td', text: 'image/tiff')
      expect(page).to have_css('tbody tr:nth-child(2) th', text: 'image2.tif')
      expect(page).to have_css('tbody tr:nth-child(2) td', text: '2 KB')
    end
  end

  context 'when the content has no file binaries' do
    it 'renders the empty message' do
      render_inline(component)

      expect(page).to have_no_css('tbody tr')
      expect(page).to have_css('p', text: 'No files yet')
    end
  end
end
