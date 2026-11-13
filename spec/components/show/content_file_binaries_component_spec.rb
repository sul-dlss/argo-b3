# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ContentFileBinariesComponent, type: :component do
  let(:component) { described_class.new(content_record: content, druid_token: 'abc123token') }

  let(:content) { create(:content, druid: 'druid:bc123df4567') }

  context 'when the content has file binaries' do
    before do
      create(:content_file_binary, content:, filepath: 'image2.tif', size: 2048, mime_type: 'image/tiff')
      create(:content_file_binary, content:, filepath: 'image1.tif', size: 1024, mime_type: 'image/tiff')
    end

    it 'renders a row for each file binary in path order' do
      render_inline(component)

      expect(page).to have_css("table#bc123df4567-files.table-h3.table-treegrid[aria-label='Files']" \
                               "[data-sdr-treegrid-remember-expanded-value='true']")
      expect(page).to have_no_css('caption')
      expect(page).to have_css('thead th:nth-of-type(1)', text: 'File/folder name')
      expect(page).to have_css('thead th:nth-of-type(2)', text: 'Type')
      expect(page).to have_css('thead th:nth-of-type(3)', text: 'Size')
      expect(page).to have_css('thead th:nth-of-type(4)', text: 'Technical metadata')
      expect(page).to have_css('tbody tr:nth-child(1) th', text: 'image1.tif')
      expect(page).to have_css('tbody tr:nth-child(1) th + td', text: 'image/tiff')
      expect(page).to have_css('tbody tr:nth-child(1) td + td', text: '1 KB')
      expect(page).to have_css('tbody tr:nth-child(2) th', text: 'image2.tif')
      expect(page).to have_css('tbody tr:nth-child(2) td + td', text: '2 KB')
      expect(page).to have_no_button('Expand all')
    end
  end

  context 'when files are in folders' do
    before do
      create(:content_file_binary, content:, filepath: 'folder1/image2.tif')
      create(:content_file_binary, content:, filepath: 'image1.tif')
    end

    it 'renders collapsed folders, with the file names of the files within them' do
      render_inline(component)

      expect(page).to have_button('Expand all')
      expect(page).to have_css('tbody tr[aria-level="1"] th', text: 'image1.tif')
      expect(page).to have_css('tbody tr[aria-level="1"][aria-expanded="false"] th', text: 'folder1')
      file_row = page.find('tbody tr[aria-level="2"][hidden]', visible: :all)
      expect(file_row.find('th', visible: :all).text(:all).strip).to eq 'image2.tif'
    end
  end

  context 'when a deposited file is staged in the open version' do
    let(:staged_filepath) { StagingSupport.staging_filepath(druid: 'druid:bc123df4567', filepath: 'image2.tif') }

    before do
      content_file_set = create(:content_file_set, content:)
      %w[image1.tif image2.tif].each do |filepath|
        content_file_binary = create(:content_file_binary, content:, filepath:, file_location: 'deposited')
        create(:content_file, content_file_set:, content_file_binary:, preserve: true)
      end
      FileUtils.mkdir_p(File.dirname(staged_filepath))
      FileUtils.touch(staged_filepath)
    end

    after do
      FileUtils.rm_rf(StagingSupport.staging_content_path(druid: 'druid:bc123df4567'))
    end

    it 'shows the technical metadata toggle only for the file that is not staged' do
      render_inline(component)

      expect(page).to have_button('View technical metadata for image1.tif')
      expect(page).to have_no_button('View technical metadata for image2.tif')
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
