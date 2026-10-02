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

    expect(page).to have_css("table.table-h3[aria-label='Files']")
    expect(page).to have_css('th', text: 'File name')
    expect(page).to have_css('tbody tr th', text: 'image1.tif')
    expect(page).to have_css('tbody tr td', text: '1 KB')
    expect(page).to have_css('tbody tr td', text: 'image/tiff')
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

      expect(page).to have_button('Delete image1.tif', class: 'disabled')
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
end
