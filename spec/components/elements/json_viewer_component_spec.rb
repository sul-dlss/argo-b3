# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::JsonViewerComponent, type: :component do
  let(:hash) { { foo: 'bar', baz: 42 } }

  context 'with default options' do
    let(:component) { described_class.new(hash:) }

    it 'renders the json-viewer element with default attributes' do
      render_inline(component)

      expect(page).to have_css('andypf-json-viewer[expanded][show-toolbar]')
      expect(page).to have_no_content('Tip: Shift + Click')
    end
  end

  context 'when expanded is false' do
    let(:component) { described_class.new(hash:, expanded: false) }

    it 'renders the json-viewer element without expanded attribute' do
      render_inline(component)

      expect(page).to have_css('andypf-json-viewer[expanded="false"]')
    end
  end

  context 'when show_toolbar is false' do
    let(:component) { described_class.new(hash:, show_toolbar: false) }

    it 'renders the json-viewer element without show-toolbar attribute' do
      render_inline(component)

      expect(page).to have_css('andypf-json-viewer[show-toolbar="false"]')
    end
  end

  context 'when show_tip is true' do
    let(:component) { described_class.new(hash:, show_tip: true) }

    it 'renders the tip paragraph' do
      render_inline(component)

      expect(page).to have_content('Tip: Shift + Click')
    end
  end
end
