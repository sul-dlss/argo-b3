# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pin::PinnedTagComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:tag) { 'Project : Foo' }

  context 'when not pinned' do
    let(:component) { described_class.new(tag:, pinned: false) }

    it 'renders a button that pins the tag' do
      render_inline(component)

      expect(page).to have_css('.bi-pin')
      expect(page).to have_no_css('.bi-pin-fill')
      expect(page).to have_css("form[action='#{pinned_tags_path}'][method='post']")
      expect(page).to have_field('tag', type: 'hidden', with: tag)
      expect(page).to have_button('Pin')
    end
  end

  context 'when pinned' do
    let(:component) { described_class.new(tag:, pinned: true) }

    it 'renders a button that unpins the tag' do
      render_inline(component)

      expect(page).to have_css('.bi-pin-fill')
      expect(page).to have_no_css('.bi-pin')
      expect(page).to have_css("form[action='#{pinned_tag_path(tag)}']")
      expect(page).to have_field('_method', type: 'hidden', with: 'delete')
      expect(page).to have_button('Unpin')
    end
  end

  context 'when not compact (the default)' do
    let(:component) { described_class.new(tag:, pinned: true) }

    it 'renders a larger icon to match the other pin buttons' do
      render_inline(component)

      expect(page).to have_css('.bi-pin-fill.fs-4')
    end
  end

  context 'when compact' do
    let(:component) { described_class.new(tag:, pinned: true, compact: true) }

    it 'renders a smaller, tightly-padded button for dense lists' do
      render_inline(component)

      expect(page).to have_css('.bi-pin-fill:not(.fs-4)')
      expect(page).to have_button('Unpin', class: 'p-0')
    end
  end
end
