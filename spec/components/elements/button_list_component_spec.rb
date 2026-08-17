# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::ButtonListComponent, type: :component do
  context 'with buttons' do
    let(:component) do
      described_class.new(title: 'Actions', help_text: '(does not require new version)')
    end

    it 'renders the title, help text, and buttons' do
      render_inline(component) do |component|
        component.with_button(link: '/reindex', label: 'Reindex', variant: 'outline-primary')
        component.with_button(link: '/republish', label: 'Republish', variant: 'outline-primary')
      end

      expect(page).to have_css('h2', text: 'Actions')
      expect(page).to have_css('small', text: '(does not require new version)')
      expect(page).to have_button('Reindex', class: 'btn btn-outline-primary mb-1')
      expect(page).to have_button('Republish', class: 'btn btn-outline-primary mb-1')
    end

    it 'defaults button classes to mb-1' do
      render_inline(component) do |component|
        component.with_button(link: '/reindex', label: 'Reindex', variant: 'outline-primary')
      end

      expect(page).to have_button('Reindex', class: 'btn btn-outline-primary mb-1')
    end

    it 'allows overriding button classes' do
      render_inline(component) do |component|
        component.with_button(link: '/reindex', label: 'Reindex', variant: 'outline-primary', classes: 'mb-3')
      end

      expect(page).to have_button('Reindex', class: 'btn btn-outline-primary mb-3')
    end
  end

  context 'without help text' do
    let(:component) { described_class.new(title: 'Discard') }

    it 'does not render a caption' do
      render_inline(component) do |component|
        component.with_button(link: '/purge', label: 'Purge item', variant: 'outline-primary')
      end

      expect(page).to have_no_css('small')
    end
  end

  context 'without buttons' do
    let(:component) { described_class.new(title: 'Actions') }

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_css('h2')
    end
  end
end
