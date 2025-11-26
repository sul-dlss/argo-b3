# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::SelectedItemComponent, type: :component do
  context 'with a provided label' do
    let(:component) do
      described_class.new(label: 'Test Label', path: '/remove/path')
    end

    it 'renders the selected item with label and remove link' do
      render_inline(component)

      expect(page).to have_css('li .selected-item-label', text: 'Test Label')
      expect(page).to have_link('', href: '/remove/path', title: 'Remove Test Label', class: 'btn-close')
    end
  end

  context 'with label_content provided' do
    let(:component) do
      described_class.new(path: '/remove/path', label: 'Test Label') do |c|
        c.label_content do
          'Custom Label Content'
        end
      end
    end

    it 'renders the selected item with label_content and remove link' do
      render_inline(component) do |component|
        component.with_label_content { 'Custom Label Content' }
      end

      expect(page).to have_css('li .selected-item-label', text: 'Custom Label Content')
      expect(page).to have_link('', href: '/remove/path', title: 'Remove Test Label', class: 'btn-close')
    end
  end
end
