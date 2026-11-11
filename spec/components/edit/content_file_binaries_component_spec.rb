# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::ContentFileBinariesComponent, type: :component do
  let(:component) do
    described_class.new(content_record: Content.with_structural_associations.find(content.id),
                        content_token: 'abc123', disabled:)
  end
  let(:disabled) { false }
  let(:content) { create(:content, druid: 'druid:bc123df4567') }
  let!(:content_file_binary) do
    create(:content_file_binary, content:, filepath: 'image1.tif', size: 1024, mime_type: 'image/tiff')
  end
  let(:delete_form_selector) { "form[action='/contents/abc123/content_file_binaries/#{content_file_binary.id}']" }

  it 'renders a row for each file binary with a delete button without confirmation' do
    render_inline(component)

    expect(page).to have_css("table#bc123df4567-content-files.table-h3[aria-label='Files']" \
                             "[data-sdr-treegrid-remember-expanded-value='true']")
    expect(page).to have_css('thead th:nth-of-type(1)', text: 'File/folder name')
    expect(page).to have_css('thead th:nth-of-type(2)', text: 'Type')
    expect(page).to have_css('thead th:nth-of-type(3)', text: 'Size')
    expect(page).to have_css('thead th:nth-of-type(4) .visually-hidden', text: 'Actions')
    expect(page).to have_css('tbody tr th.fw-normal[scope="row"]', text: 'image1.tif')
    expect(page).to have_css('tbody tr th + td', text: 'image/tiff')
    expect(page).to have_css('tbody tr td + td', text: '1 KB')
    expect(page).to have_css(delete_form_selector)
    expect(page).to have_no_css('form[data-turbo-confirm]')
    expect(page).to have_css('input[name="_method"][value="delete"]', visible: :hidden)
    expect(page).to have_button('Delete image1.tif')
    expect(page).to have_no_button(class: 'disabled')
  end

  context 'when the binary is not the only file in its resource' do
    before do
      content_file_set = create(:content_file_set, content:)
      create(:content_file, content_file_set:, content_file_binary:, position: 1)
      create(:content_file, content_file_set:, position: 2,
                            content_file_binary: create(:content_file_binary, content:, filepath: 'image2.tif'))
    end

    it 'does not confirm' do
      render_inline(component)

      expect(page).to have_no_css('form[data-turbo-confirm]')
    end
  end

  context 'when deleting the binary would empty a resource' do
    before do
      create(:content_file_set, content:, position: 1)
      create(:content_file, content_file_set: create(:content_file_set, content:, position: 2), content_file_binary:)
    end

    it 'confirms, naming the resource' do
      render_inline(component)

      expect(page).to have_css(
        "#{delete_form_selector}[data-turbo-confirm='Deleting image1.tif will also delete resource 2. Continue?']"
      )
    end
  end

  context 'when deleting the binary would empty multiple resources' do
    before do
      create(:content_file, content_file_set: create(:content_file_set, content:, position: 1), content_file_binary:)
      create(:content_file, content_file_set: create(:content_file_set, content:, position: 2), content_file_binary:)
    end

    it 'confirms, naming the resources' do
      render_inline(component)

      expect(page).to have_css(
        "#{delete_form_selector}" \
        "[data-turbo-confirm='Deleting image1.tif will also delete resources 1 and 2. Continue?']"
      )
    end
  end

  context 'when disabled' do
    let(:disabled) { true }

    it 'disables the delete button' do
      render_inline(component)

      expect(page).to have_button('Delete image1.tif', class: 'disabled', disabled: true)
    end
  end

  context 'when the content has no file binaries' do
    let(:component) { described_class.new(content_record: create(:content), content_token: 'abc123') }

    it 'renders the empty message' do
      render_inline(component)

      expect(page).to have_no_css('tbody tr')
      expect(page).to have_css('p', text: 'No files yet')
    end
  end

  context 'when files are in folders' do
    before do
      create(:content_file_binary, content:, filepath: 'folder1/sub1/image3.tif')
      create(:content_file_binary, content:, filepath: 'folder1/image2.tif')
    end

    it 'renders collapsed folder rows without actions, and files with their file names and delete buttons' do
      render_inline(component)

      rows = page.all('tbody tr[aria-level]', visible: :all).map do |row|
        [row['aria-level'], row.find('th', visible: :all).text(:all).strip]
      end
      expect(rows).to eq [%w[1 image1.tif], %w[1 folder1], %w[2 image2.tif], %w[2 sub1], %w[3 image3.tif]]
      expect(page).to have_css('tr[data-sdr-treegrid-role="folder"][aria-expanded="false"]', count: 2, visible: :all)
      expect(page).to have_no_css('tr[data-sdr-treegrid-role="folder"] button', visible: :all)
      expect(page).to have_button('Delete folder1/sub1/image3.tif', visible: :all)
      expect(page).to have_button('Expand all')
    end
  end
end
