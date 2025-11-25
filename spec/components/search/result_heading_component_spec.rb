# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::ResultHeadingComponent, type: :component do
  context 'with label and path' do
    let(:component) do
      described_class.new(index: 1, label: 'Test Label', path: '/test/path')
    end

    it 'renders the heading with link' do
      render_inline(component)

      expect(page).to have_link('Test Label', href: '/test/path')
      expect(page).to have_css('h4 span', text: '1.')
    end
  end

  context 'with link slot' do
    let(:component) do
      described_class.new(index: 2)
    end

    it 'renders the heading with custom link' do
      render_inline(component) do |component|
        component.with_link do
          '<a href="/custom/path">Custom Link</a>'.html_safe
        end
      end

      expect(page).to have_link('Custom Link', href: '/custom/path')
      expect(page).to have_css('h4 span', text: '2.')
    end
  end
end
