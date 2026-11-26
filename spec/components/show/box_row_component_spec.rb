# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::BoxRowComponent, type: :component do
  it 'renders the boxes in order within the row, with the given attributes' do
    render_inline(described_class.new(id: 'box-row', role: 'status')) do
      '<div class="show-box">First</div><div class="show-box">Second</div>'.html_safe
    end

    expect(page).to have_css('div#box-row[role="status"] > .show-box:first-child', text: 'First')
    expect(page).to have_css('div#box-row[role="status"] > .show-box:last-child', text: 'Second')
  end

  it 'lays out a third of the row for each box by default' do
    render_inline(described_class.new) { '<div class="show-box">First</div>'.html_safe }

    expect(page).to have_css('div.row.row-cols-1.row-cols-xl-3.g-4 > .show-box')
    expect(page).to have_no_css('.box-row-compact')
  end

  it 'lays out compact boxes with centered text when compact' do
    render_inline(described_class.new(compact: true, classes: 'mb-2')) { '<div class="show-box">First</div>'.html_safe }

    expect(page).to have_css('div.box-row-compact.d-flex.flex-wrap.column-gap-5.row-gap-3.text-center.mb-2 > .show-box')
    expect(page).to have_no_css('.row')
  end
end
