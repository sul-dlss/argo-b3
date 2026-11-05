# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::VersionRowComponent, type: :component do
  let(:component) { described_class.new(version:, cocina_object:) }
  let(:cocina_object) { build(:dro_with_metadata, id: 'druid:bc123df4567') }
  let(:version) do
    VersionsPresenter::Version.new(version: 2, user_version: 1, description: 'Second version',
                                   opened_at: '2021-03-31 20:23:30 +0000', accessioned_at: '2021-03-31 21:02:03 +0000',
                                   purl_url: 'https://purl.stanford.edu/bc123df4567/version/1', withdrawn: false)
  end
  let(:table) do
    Capybara.string("<table><tbody>#{component.render_in(vc_test_view_context)}</tbody></table>")
  end

  it 'renders the version in a single row' do
    expect(table).to have_css('tbody > tr', count: 1)
    expect(table.all('td').map { |cell| cell.text.squish }).to eq(
      ['2', 'Second version', '1', '2021-03-31 13:23:30 PT', '2021-03-31 14:02:03 PT', 'PURL']
    )
    expect(table).to have_link('PURL', href: 'https://purl.stanford.edu/bc123df4567/version/1')
  end

  context 'when the user version is withdrawn' do
    let(:version) do
      VersionsPresenter::Version.new(version: 2, user_version: 1, description: 'Second version', withdrawn: true)
    end

    it 'renders the user version as withdrawn' do
      expect(table.all('td')[2]).to have_text('1 (withdrawn)')
    end
  end

  context 'when the object is a virtual object' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: 'druid:bc123df4567').new(
        structural: { hasMemberOrders: [{ members: ['druid:hj456kl7890'] }] }
      )
    end

    it 'renders the user version and PURL cells' do
      expect(table.all('td').map { |cell| cell.text.squish }).to eq(
        ['2', 'Second version', '1', '2021-03-31 13:23:30 PT', '2021-03-31 14:02:03 PT', 'PURL']
      )
    end
  end

  context 'when the object is an agreement' do
    let(:cocina_object) { build(:dro_with_metadata, id: 'druid:bc123df4567', type: Cocina::Models::ObjectType.agreement) }

    it 'omits the user version and PURL cells' do
      expect(table.all('td').map { |cell| cell.text.squish }).to eq(
        ['2', 'Second version', '2021-03-31 13:23:30 PT', '2021-03-31 14:02:03 PT']
      )
    end
  end

  context 'when the object is a collection' do
    let(:cocina_object) { build(:collection_with_metadata, id: 'druid:bc123df4567') }

    it 'omits the user version and PURL cells' do
      expect(table.all('td').map { |cell| cell.text.squish }).to eq(
        ['2', 'Second version', '2021-03-31 13:23:30 PT', '2021-03-31 14:02:03 PT']
      )
    end
  end

  context 'when the object is an APO' do
    let(:cocina_object) { build(:admin_policy_with_metadata, id: 'druid:bc123df4567') }

    it 'omits the user version and PURL cells' do
      expect(table.all('td').map { |cell| cell.text.squish }).to eq(
        ['2', 'Second version', '2021-03-31 13:23:30 PT', '2021-03-31 14:02:03 PT']
      )
    end
  end

  context 'when the version has no user version, accessioned date, or PURL' do
    let(:version) do
      VersionsPresenter::Version.new(version: 3, description: 'Third version', opened_at: '2021-04-01 20:23:30 +0000')
    end

    it 'renders empty cells' do
      expect(table.all('td').map { |cell| cell.text.strip }).to eq(
        ['3', 'Third version', '', '2021-04-01 13:23:30 PT', '', '']
      )
      expect(table).to have_no_link
    end
  end
end
