# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::BoxRowComponent, type: :component do
  it 'renders the boxes in order within the row, with the given attributes' do
    render_inline(described_class.new(id: 'box-row', role: 'status')) do
      '<div class="show-box">First</div><div class="show-box">Second</div>'.html_safe
    end

    expect(page).to have_css('div#box-row[role="status"].row.row-cols-xl-3 > .show-box:first-child', text: 'First')
    expect(page).to have_css('div#box-row[role="status"] > .show-box:last-child', text: 'Second')
    expect(page).to have_no_css('.box-row-compact')
  end

  context 'when compact' do
    it 'renders the boxes in a wrapping compact row rather than a grid row' do
      render_inline(described_class.new(compact: true, classes: 'mb-2')) do
        '<div class="card">First</div><div class="card">Second</div>'.html_safe
      end

      expect(page).to have_css('div.box-row-compact.d-flex.flex-wrap.mb-2 > .card:first-child', text: 'First')
      expect(page).to have_css('div.box-row-compact > .card:last-child', text: 'Second')
      expect(page).to have_no_css('.row')
    end
  end
end
