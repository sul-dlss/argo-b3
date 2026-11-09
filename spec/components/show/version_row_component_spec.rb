# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::VersionRowComponent, type: :component do
  let(:component) { described_class.new(version:, cocina_object:, druid_token: 'token', manage_user_versions:) }
  let(:cocina_object) { build(:dro_with_metadata, id: 'druid:bc123df4567') }
  let(:manage_user_versions) { true }
  let(:version) do
    VersionsPresenter::Version.new(version: 2, user_version: 1, description: 'Second version',
                                   opened_at: '2021-03-31 20:23:30 +0000', accessioned_at: '2021-03-31 21:02:03 +0000',
                                   purl_url: 'https://purl.stanford.edu/bc123df4567/version/1', cocina: true,
                                   withdrawn: false, withdrawable: false, restorable: false)
  end
  let(:table) do
    Capybara.string("<table><tbody>#{component.render_in(vc_test_view_context)}</tbody></table>")
  end

  it 'renders the version in a single row without a user version button' do
    expect(table).to have_css('tbody > tr', count: 1)
    expect(table.all('td').map { |cell| cell.text.squish }).to eq(
      ['2', 'Second version', '1', '2021-03-31 13:23:30 PT', '2021-03-31 14:02:03 PT',
       'Cocina Structural metadata Descriptive metadata', 'PURL']
    )
    expect(table).to have_link('PURL', href: 'https://purl.stanford.edu/bc123df4567/version/1')
    expect(table).to have_no_button
  end

  it 'renders the download links in a list' do
    download_cell = table.all('td')[5]
    expect(download_cell).to have_css('ul.list-unstyled li', count: 3)
    expect(download_cell).to have_link('Cocina', href: '/objects/token/versions/2/cocina')
    expect(download_cell.find_link('Cocina')[:target]).to eq('_blank')
    expect(download_cell).to have_css('a i.bi-box-arrow-up-right')
    expect(download_cell).to have_link('Structural metadata', href: '/objects/token/versions/2/structural_csv')
    expect(download_cell).to have_link('Descriptive metadata', href: '/objects/token/versions/2/descriptive_csv')
  end

  context 'when the user version is withdrawable' do
    let(:version) do
      VersionsPresenter::Version.new(version: 2, user_version: 1, description: 'Second version', withdrawable: true)
    end

    it 'renders a withdraw button' do
      user_version_cell = table.all('td')[2]
      expect(user_version_cell).to have_text('1')
      expect(user_version_cell).to have_no_text('withdrawn')
      form = user_version_cell.find("form[action='/objects/druid:bc123df4567/user_versions/1/withdraw']")
      expect(form[:method]).to eq('post')
      expect(form).to have_button('Withdraw')
      expect(user_version_cell).to have_no_button('Restore')
    end

    context 'when the user cannot manage user versions' do
      let(:manage_user_versions) { false }

      it 'renders a disabled withdraw button' do
        expect(table).to have_button('Withdraw', disabled: true)
      end
    end
  end

  context 'when the user version is restorable' do
    let(:version) do
      VersionsPresenter::Version.new(version: 2, user_version: 1, description: 'Second version', withdrawn: true,
                                     restorable: true)
    end

    it 'renders the user version as withdrawn with a restore button' do
      user_version_cell = table.all('td')[2]
      expect(user_version_cell).to have_text('1 (withdrawn)')
      expect(user_version_cell.find("form[action='/objects/druid:bc123df4567/user_versions/1/restore']"))
        .to have_button('Restore')
      expect(user_version_cell).to have_no_button('Withdraw')
    end

    context 'when the user cannot manage user versions' do
      let(:manage_user_versions) { false }

      it 'renders the user version as withdrawn with a disabled restore button' do
        expect(table.all('td')[2]).to have_text('1 (withdrawn)')
        expect(table).to have_button('Restore', disabled: true)
      end
    end
  end

  context 'when the user version is permanently withdrawn' do
    let(:version) do
      VersionsPresenter::Version.new(version: 2, user_version: 1, description: 'Second version', withdrawn: true)
    end

    it 'renders the user version as withdrawn without a button' do
      expect(table.all('td')[2]).to have_text('1 (withdrawn)')
      expect(table).to have_no_button
    end
  end

  context 'when the object is a virtual object' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: 'druid:bc123df4567').new(
        structural: { hasMemberOrders: [{ members: ['druid:hj456kl7890'] }] }
      )
    end

    it 'renders all the download links' do
      expect(table).to have_link('Cocina')
      expect(table).to have_link('Structural metadata')
      expect(table).to have_link('Descriptive metadata')
    end
  end

  context 'when the object is an agreement' do
    let(:cocina_object) { build(:dro_with_metadata, id: 'druid:bc123df4567', type: Cocina::Models::ObjectType.agreement) }

    it 'renders only the cocina link and omits the user version and PURL cells' do
      expect(table.all('td').map { |cell| cell.text.squish }).to eq(
        ['2', 'Second version', '2021-03-31 13:23:30 PT', '2021-03-31 14:02:03 PT', 'Cocina']
      )
      expect(table).to have_no_link('PURL')
    end
  end

  context 'when the object is a collection' do
    let(:cocina_object) { build(:collection_with_metadata, id: 'druid:bc123df4567') }

    it 'omits the structural metadata link and the user version and PURL cells' do
      expect(table.all('td').map { |cell| cell.text.squish }).to eq(
        ['2', 'Second version', '2021-03-31 13:23:30 PT', '2021-03-31 14:02:03 PT', 'Cocina Descriptive metadata']
      )
      expect(table).to have_no_link('PURL')
    end
  end

  context 'when the object is an APO' do
    let(:cocina_object) { build(:admin_policy_with_metadata, id: 'druid:bc123df4567') }

    it 'renders only the cocina link and omits the user version and PURL cells' do
      expect(table.all('td').map { |cell| cell.text.squish }).to eq(
        ['2', 'Second version', '2021-03-31 13:23:30 PT', '2021-03-31 14:02:03 PT', 'Cocina']
      )
      expect(table).to have_no_link('PURL')
    end
  end

  context 'when the version has no stored cocina, user version, accessioned date, or PURL' do
    let(:version) do
      VersionsPresenter::Version.new(version: 3, description: 'Third version', opened_at: '2021-04-01 20:23:30 +0000',
                                     cocina: false)
    end

    it 'renders empty cells' do
      expect(table.all('td').map { |cell| cell.text.strip }).to eq(
        ['3', 'Third version', '', '2021-04-01 13:23:30 PT', '', '', '']
      )
      expect(table).to have_no_link
    end
  end
end
