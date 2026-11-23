# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ManageFilesButtonComponent, type: :component do
  subject(:component) { described_class.new(druid:, label: 'Edit files and structure', enabled:) }

  let(:druid) { 'druid:bc123df4567' }

  context 'when enabled' do
    let(:enabled) { true }

    it 'renders a link to managing files that opens on structure files' do
      render_inline(component)

      expect(page).to have_link('Edit files and structure', href: "/contents/#{druid}/edit?open_on=structure")
      expect(page).to have_no_css('a.disabled', text: 'Edit files and structure')
    end
  end

  context 'when not enabled' do
    let(:enabled) { false }

    it 'renders a disabled link' do
      render_inline(component)

      expect(page).to have_css('a.disabled[aria-disabled="true"]', text: 'Edit files and structure')
      expect(page).to have_no_link('Edit files and structure')
    end
  end
end
