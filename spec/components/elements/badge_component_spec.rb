# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::BadgeComponent, type: :component do
  context 'with the object type variant' do
    it 'renders a bold, object-type-colored pill' do
      render_inline(described_class.new(label: 'Item', variant: :object_type, size: :medium, tag: :div,
                                        classes: 'object-type-pill'))

      expect(page).to have_css('div.object-type-pill.object-type-bg.fw-bold.fs-5.text-uppercase.rounded-pill',
                               text: 'Item')
    end
  end

  context 'with the status variant' do
    it 'renders a semibold, bordered pill' do
      render_inline(described_class.new(label: 'Read only', variant: :status, size: :large))

      expect(page).to have_css('span.status-badge.fw-semibold.border.border-dark.fs-4.text-uppercase.rounded-pill',
                               text: 'Read only')
      expect(page).to have_no_css('.object-type-bg')
    end
  end
end
