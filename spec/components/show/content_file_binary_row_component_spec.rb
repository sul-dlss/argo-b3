# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ContentFileBinaryRowComponent, type: :component do
  let(:component) { described_class.new(content_file_binary:, druid_token: 'abc123token') }

  let(:content) { create(:content) }

  # Rendered within a table since rows outside of a table are dropped when parsed.
  def render_row
    render_in_view_context(component) { |row_component| tag.table(tag.tbody(render(row_component))) }
  end

  context 'when the file binary is not deposited' do
    let(:content_file_binary) do
      create(:content_file_binary, content:, filepath: 'image1.tif', size: 1024, mime_type: 'image/tiff')
    end

    it 'renders a row without a technical metadata toggle' do
      render_row

      expect(page).to have_css('tr th', text: 'image1.tif')
      expect(page).to have_css('tr td', text: '1 KB')
      expect(page).to have_css('tr td', text: 'image/tiff')
      expect(page).to have_no_css('tr.toggle-row')
      expect(page).to have_no_css('tr.toggle-row-data')
      expect(page).to have_no_css('turbo-frame')
    end
  end

  context 'when the file binary is deposited and preserved' do
    let(:content_file_binary) do
      create(:content_file_binary, content:, filepath: 'folder1/image1.tif', file_location: 'deposited')
    end

    before do
      create(:content_file, content_file_set: create(:content_file_set, content:), content_file_binary:, preserve: true)
    end

    it 'renders a toggle row and a collapsed row that lazily loads the technical metadata' do
      render_row

      data_id = "content-file-binary-#{content_file_binary.id}-technical-metadata"
      expect(page).to have_css(
        "tr.toggle-row.collapsed[data-bs-toggle='collapse'][data-bs-target='##{data_id}']" \
        "[aria-expanded='false'][aria-controls='#{data_id}'] span.toggle-row-indicator"
      )
      expect(page).to have_css("tr##{data_id}.toggle-row-data.collapse td[colspan='4']")
      expect(page).to have_css(
        "tr##{data_id} turbo-frame##{data_id}-frame[loading='lazy'][data-turbo-permanent]" \
        "[src='/objects/abc123token/technical_metadata?filepath=folder1%2Fimage1.tif']"
      )
    end
  end

  context 'when the file binary is deposited but not preserved' do
    let(:content_file_binary) { create(:content_file_binary, content:, file_location: 'deposited') }

    before do
      create(:content_file, content_file_set: create(:content_file_set, content:), content_file_binary:,
                            preserve: false, shelve: false)
    end

    it 'does not render a technical metadata toggle' do
      render_row

      expect(page).to have_css('tr')
      expect(page).to have_no_css('tr.toggle-row')
      expect(page).to have_no_css('turbo-frame')
    end
  end

  context 'when the file binary is deposited but not referenced by a file' do
    let(:content_file_binary) { create(:content_file_binary, content:, file_location: 'deposited') }

    it 'does not render a technical metadata toggle' do
      render_row

      expect(page).to have_css('tr')
      expect(page).to have_no_css('tr.toggle-row')
      expect(page).to have_no_css('turbo-frame')
    end
  end
end
