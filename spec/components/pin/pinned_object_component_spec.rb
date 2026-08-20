# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pin::PinnedObjectComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:druid) { 'druid:bc123df4567' }

  context 'when not pinned' do
    let(:component) { described_class.new(druid:, pinned: false) }

    it 'renders a button that pins the object' do
      render_inline(component)

      expect(page).to have_css('.bi-pin')
      expect(page).to have_no_css('.bi-pin-fill')
      expect(page).to have_css("form[action='#{pinned_objects_path}'][method='post']")
      expect(page).to have_field('druid', type: 'hidden', with: druid)
      expect(page).to have_button('Pin')
    end
  end

  context 'when pinned' do
    let(:component) { described_class.new(druid:, pinned: true) }

    it 'renders a button that unpins the object' do
      render_inline(component)

      expect(page).to have_css('.bi-pin-fill')
      expect(page).to have_no_css('.bi-pin')
      expect(page).to have_css("form[action='#{pinned_object_path(druid)}']")
      expect(page).to have_field('_method', type: 'hidden', with: 'delete')
      expect(page).to have_button('Unpin')
    end
  end
end
