# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::TechnicalMetadataToggleComponent, type: :component do
  let(:component) { described_class.new(content_file_binary:, druid_token: 'abc123token') }

  let(:content) { create(:content) }

  context 'when the file binary is not deposited' do
    let(:content_file_binary) { create(:content_file_binary, content:, filepath: 'image1.tif') }

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_button
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

    it 'renders a View button and collapsed content that lazily loads the technical metadata' do
      render_inline(component)

      data_id = "content-file-binary-#{content_file_binary.id}-technical-metadata"
      expect(page).to have_css(
        "button.btn-link.collapsed[type='button'][data-bs-toggle='collapse'][data-bs-target='##{data_id}']" \
        "[data-sdr-treegrid-target='fileAction'][aria-expanded='false'][aria-controls='#{data_id}'] i.bi-chevron-right"
      )
      expect(page).to have_button('View technical metadata for folder1/image1.tif')
      expect(page).to have_css(
        "div##{data_id}.collapse turbo-frame##{data_id}-frame[loading='lazy'][data-turbo-permanent]" \
        "[src='/objects/abc123token/technical_metadata?filepath=folder1%2Fimage1.tif']", visible: :all
      )
    end
  end

  context 'when the file binary is deposited but not preserved' do
    let(:content_file_binary) { create(:content_file_binary, content:, file_location: 'deposited') }

    before do
      create(:content_file, content_file_set: create(:content_file_set, content:), content_file_binary:,
                            preserve: false, shelve: false)
    end

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_button
      expect(page).to have_no_css('turbo-frame')
    end
  end

  context 'when the file binary is deposited but not referenced by a file' do
    let(:content_file_binary) { create(:content_file_binary, content:, file_location: 'deposited') }

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_button
      expect(page).to have_no_css('turbo-frame')
    end
  end
end
