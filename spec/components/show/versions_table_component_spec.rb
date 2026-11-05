# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::VersionsTableComponent, type: :component do
  let(:component) { described_class.new(versions:, cocina_object:, druid_token: 'token') }
  let(:cocina_object) { build(:dro_with_metadata, id: 'druid:bc123df4567') }
  let(:versions) do
    [
      VersionsPresenter::Version.new(version: 2, description: 'Second version', withdrawable: true, user_version: 1),
      VersionsPresenter::Version.new(version: 1, description: 'Initial version')
    ]
  end
  let(:user) { create(:user) }

  before do
    allow(Current).to receive_messages(user:, effective_groups: user.groups)
  end

  context 'when the user can edit the object' do
    before do
      create(:permission, :edit, workgroup: user.groups.first, target_druid: 'druid:bc123df4567')
    end

    it 'renders the headers, a row for each version, and the withdraw button' do
      render_inline(component)

      expect(page.all('#versions-table th').map { |header| header.text.strip }).to eq(
        ['Version', 'Description', 'Public version', 'Registered / opened', 'Deposited', 'Download', 'PURL']
      )
      expect(page.all('#versions-table tbody tr').map { |row| row.first('td').text.strip }).to eq(%w[2 1])
      expect(page).to have_button('Withdraw')
    end
  end

  context 'when the object is a collection' do
    let(:cocina_object) { build(:collection_with_metadata, id: 'druid:bc123df4567') }

    it 'omits the user version and PURL headers' do
      render_inline(component)

      expect(page.all('#versions-table th').map { |header| header.text.strip }).to eq(
        ['Version', 'Description', 'Registered / opened', 'Deposited', 'Download']
      )
      expect(page).to have_no_button('Withdraw')
    end
  end

  context 'when the user cannot edit the object' do
    it 'renders a disabled withdraw button' do
      render_inline(component)

      expect(page.all('#versions-table tbody tr').count).to eq(2)
      expect(page).to have_button('Withdraw', disabled: true)
    end
  end
end
