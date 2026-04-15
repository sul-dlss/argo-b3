# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::Tables::CellComponent, type: :component do
  context 'when rendered with default options' do
    it 'renders a table cell with the provided content' do
      render_inline(described_class.new) { 'Cell value' }
      page = Capybara.string("<table><tbody><tr>#{rendered_content}</tr></tbody></table>")

      expect(page).to have_css('td', text: 'Cell value')
      expect(page).to have_no_css('td[colspan]')
    end
  end

  context 'when rendered with a colspan and classes' do
    it 'renders the colspan and merged classes on the table cell' do
      render_inline(described_class.new(colspan: 5, classes: %w[ps-5 text-danger])) { 'Error details' }
      page = Capybara.string("<table><tbody><tr>#{rendered_content}</tr></tbody></table>")

      expect(page).to have_css('td[colspan="5"].ps-5.text-danger', text: 'Error details')
    end
  end
end
