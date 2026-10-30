# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ManageFilesButtonComponent, type: :component do
  subject(:component) { described_class.new(druid:, enabled:) }

  let(:druid) { 'druid:bc123df4567' }

  context 'when enabled' do
    let(:enabled) { true }

    it 'renders a link to manage files' do
      render_inline(component)

      expect(page).to have_link('Manage files', href: "/contents/#{druid}/edit")
      expect(page).to have_no_css('a.disabled', text: 'Manage files')
    end
  end

  context 'when not enabled' do
    let(:enabled) { false }

    it 'renders a disabled link' do
      render_inline(component)

      expect(page).to have_css('a.disabled[aria-disabled="true"]', text: 'Manage files')
      expect(page).to have_no_link('Manage files')
    end
  end
end
