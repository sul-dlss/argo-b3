# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::JsonViewerComponent, type: :component do
  let(:hash) { { foo: 'bar', baz: 42 } }

  context 'with default options' do
    let(:component) { described_class.new(hash:, label: 'Test JSON') }

    it 'renders the json-viewer element without the toolbar and with the expand and collapse buttons' do
      render_inline(component)

      expect(page).to have_css('div[data-controller="json-viewer"] ' \
                               'andypf-json-viewer[expanded][show-toolbar="false"][data-json-viewer-target="viewer"]')
      expect(page).to have_button('Expand all')
      expect(page).to have_css('button[data-action="json-viewer#expandAll"]')
      expect(page).to have_button('Collapse all')
      expect(page).to have_css('button[data-action="json-viewer#collapseAll"]')
    end

    it 'renders the json-viewer element as a focusable, labelled region' do
      render_inline(component)

      expect(page).to have_css('andypf-json-viewer.d-block[role="region"][tabindex="0"][aria-label="Test JSON"]')
    end

    it 'renders the json in the data attribute' do
      render_inline(component)

      expect(page.find('andypf-json-viewer')['data']).to eq('{"foo":"bar","baz":42}')
    end
  end

  context 'when expanded is false' do
    let(:component) { described_class.new(hash:, label: 'Test JSON', expanded: false) }

    it 'renders the json-viewer element without expanded attribute' do
      render_inline(component)

      expect(page).to have_css('andypf-json-viewer[expanded="false"]')
    end
  end

  context 'when show_expand_buttons is false' do
    let(:component) { described_class.new(hash:, label: 'Test JSON', show_expand_buttons: false) }

    it 'does not render the expand and collapse buttons' do
      render_inline(component)

      expect(page).to have_css('andypf-json-viewer')
      expect(page).to have_no_button('Expand all')
      expect(page).to have_no_button('Collapse all')
    end
  end
end
