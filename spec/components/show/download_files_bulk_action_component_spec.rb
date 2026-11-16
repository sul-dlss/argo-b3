# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::DownloadFilesBulkActionComponent, type: :component do
  subject(:component) { described_class.new(druid_token: 'abc123', downloadable_files:) }

  let(:downloadable_files) do
    instance_double(DownloadableFiles, empty?: empty, too_large?: too_large, total_size: 12_884_901_888)
  end
  let(:empty) { false }
  let(:too_large) { false }

  context 'when files can be downloaded' do
    it 'renders an enabled button that starts the bulk action' do
      render_inline(component)

      expect(page).to have_css("form[action='/objects/abc123/download_files_bulk_action'][method='post'] " \
                               'button:not([disabled])', text: 'Start download files bulk action')
      expect(page).to have_no_css('p')
    end
  end

  context 'when no files are available' do
    let(:empty) { true }

    it 'renders a disabled button with the reason' do
      render_inline(component)

      expect(page).to have_button('Start download files bulk action', disabled: true)
      expect(page).to have_text('No files are available to download.')
    end
  end

  context 'when the files are too large' do
    let(:too_large) { true }

    it 'renders a disabled button with the reason' do
      render_inline(component)

      expect(page).to have_button('Start download files bulk action', disabled: true)
      expect(page).to have_text('The files total 12 GB, more than the 10 GB that can be downloaded.')
    end
  end
end
