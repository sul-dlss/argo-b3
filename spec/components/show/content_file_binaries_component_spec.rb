# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ContentFileBinariesComponent, type: :component do
  let(:component) { described_class.new(content_record: content, druid_token: 'abc123token') }

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
      expect(page).to have_css('th span.visually-hidden', text: 'Show technical metadata')
      expect(page).to have_css('tbody tr:nth-child(1) th', text: 'image1.tif')
      expect(page).to have_css('tbody tr:nth-child(1) td', text: '1 KB')
      expect(page).to have_css('tbody tr:nth-child(1) td', text: 'image/tiff')
      expect(page).to have_css('tbody tr:nth-child(2) th', text: 'image2.tif')
      expect(page).to have_css('tbody tr:nth-child(2) td', text: '2 KB')
    end

    it 'does not render technical metadata toggles for files that are not deposited' do
      render_inline(component)

      expect(page).to have_no_css('tr.toggle-row')
      expect(page).to have_no_css('tr.toggle-row-data')
      expect(page).to have_no_css('turbo-frame')
    end
  end

  context 'when a file binary is deposited and preserved' do
    let(:content_file_binary) do
      create(:content_file_binary, content:, filepath: 'folder1/image1.tif', file_location: 'deposited')
    end

    before do
      create(:content_file, content_file_set: create(:content_file_set, content:), content_file_binary:, preserve: true)
    end

    it 'renders a toggle row and a collapsed row that lazily loads the technical metadata' do
      render_inline(component)

      data_id = "content-file-binary-#{content_file_binary.id}-technical-metadata"
      expect(page).to have_css(
        "tbody tr.toggle-row.collapsed[data-bs-toggle='collapse'][data-bs-target='##{data_id}']" \
        "[aria-expanded='false'][aria-controls='#{data_id}'] span.toggle-row-indicator"
      )
      expect(page).to have_css("tbody tr##{data_id}.toggle-row-data.collapse td[colspan='4']")
      expect(page).to have_css(
        "tr##{data_id} turbo-frame##{data_id}-frame[loading='lazy'][data-turbo-permanent]" \
        "[src='/objects/abc123token/technical_metadata?filepath=folder1%2Fimage1.tif']"
      )
    end
  end

  context 'when a file binary is deposited but not preserved' do
    before do
      content_file_binary = create(:content_file_binary, content:, file_location: 'deposited')
      create(:content_file, content_file_set: create(:content_file_set, content:), content_file_binary:,
                            preserve: false, shelve: false)
    end

    it 'does not render a technical metadata toggle' do
      render_inline(component)

      expect(page).to have_no_css('tr.toggle-row')
      expect(page).to have_no_css('turbo-frame')
    end
  end

  context 'when a file binary is deposited but not referenced by a file' do
    before do
      create(:content_file_binary, content:, file_location: 'deposited')
    end

    it 'does not render a technical metadata toggle' do
      render_inline(component)

      expect(page).to have_no_css('tr.toggle-row')
      expect(page).to have_no_css('turbo-frame')
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
