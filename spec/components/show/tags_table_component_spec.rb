# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::TagsTableComponent, type: :component do
  let(:component) { described_class.new(tags:, tickets:) }
  let(:tags) { ['Registered By : jdoe', 'Remediated By : labtech'] }
  let(:tickets) { %w[TESTREQ-1 TESTREQ-2] }

  it 'renders the tags table with tags and tickets' do
    render_inline(component)

    expect(page).to have_table(id: 'tags-table')
    expect(page).to have_css('table caption', text: 'Tags')
    expect(page).to have_css('th', text: 'Tags')
    expect(page).to have_css('td', text: 'Registered By : jdoe, Remediated By : labtech')
    expect(page).to have_css('th', text: 'Tickets')
    expect(page).to have_css('td', text: 'TESTREQ-1, TESTREQ-2')
  end

  context 'when tags and tickets are nil' do
    let(:tags) { nil }
    let(:tickets) { nil }

    it 'renders empty rows' do
      render_inline(component)

      expect(page).to have_table(id: 'tags-table')
      expect(page).to have_css('th', text: 'Tags')
      expect(page).to have_css('th', text: 'Tickets')
    end
  end
end
