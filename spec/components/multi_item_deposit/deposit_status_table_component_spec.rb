# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::DepositStatusTableComponent, type: :component do
  let(:component) { described_class.new(object_status_presenters:) }
  let(:object_status_presenters) do
    { 'druid:bc123df4567' => version_service_double(closed?: true), 'druid:cd234fg5678' => version_service_double }
      .map do |druid, version_service|
        ObjectStatusPresenter.new(document: SolrDocPresenter.new(solr_doc: build(:solr_item, druid:)),
                                  version_service:, content: nil)
      end
  end

  it 'renders a row for each object' do
    render_inline(component)

    table = page.find('table[aria-label="Deposit status"]')
    expect(table).to have_no_css('caption')
    expect(table.all('th').map { |header| header.text.strip }).to eq(%w[Druid Status])

    rows = table.all('tbody tr')
    expect(rows.map { |row| row.all('td').map { |cell| cell.text.strip } })
      .to eq([%w[bc123df4567 Deposited], ['cd234fg5678', 'Draft, not deposited']])
    expect(rows[0]).to have_css('td i.bi-check-circle-fill')
    expect(rows[0]).to have_link('bc123df4567', href: '/objects/druid:bc123df4567')
    expect(rows[1]).to have_link('cd234fg5678', href: '/objects/druid:cd234fg5678')
  end
end
