# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::VersionsTableComponent, type: :component do
  let(:component) { described_class.new(versions:, cocina_object:, druid_token: 'token') }
  let(:cocina_object) { build(:dro_with_metadata, id: 'druid:bc123df4567') }
  let(:versions) do
    [
      VersionsPresenter::Version.new(version: 2, description: 'Second version', user_version: 1),
      VersionsPresenter::Version.new(version: 1, description: 'Initial version')
    ]
  end

  it 'renders the headers and a row for each version' do
    render_inline(component)

    expect(page.all('#versions-table th').map { |header| header.text.strip }).to eq(
      ['Version', 'Description', 'Public version', 'Registered / opened', 'Deposited', 'Download', 'PURL']
    )
    expect(page.all('#versions-table tbody tr').map { |row| row.first('td').text.strip }).to eq(%w[2 1])
  end

  context 'when the object is a collection' do
    let(:cocina_object) { build(:collection_with_metadata, id: 'druid:bc123df4567') }

    it 'omits the public version and PURL headers' do
      render_inline(component)

      expect(page.all('#versions-table th').map { |header| header.text.strip }).to eq(
        ['Version', 'Description', 'Registered / opened', 'Deposited', 'Download']
      )
    end
  end
end
