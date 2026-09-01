# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show dashboard', :rack_test do
  context 'when signed in as a regular user' do
    before { sign_in(create(:user)) }

    it 'displays the button lists and tables, but not the admin button list' do
      visit root_path

      expect(page).to have_css('h1', text: 'Argo dashboard')

      expect(page).to have_css('h2', text: 'Register & deposit single object')
      expect(page).to have_button('Item', class: 'disabled')

      expect(page).to have_css('h2', text: 'Register or deposit multiple items')
      expect(page).to have_button('Register multiple items', class: 'disabled')

      expect(page).to have_no_css('h2', text: 'Admin')
      expect(page).to have_no_button('Manage permissions')
      expect(page).to have_no_button('Impersonate')

      expect(page).to have_css('table[aria-label="Recent objects"]')
      expect(page).to have_css('table[aria-label="Pinned searches"]')
      expect(page).to have_css('table[aria-label="Pinned items"]')
      expect(page).to have_css('table[aria-label="Pinned collections"]')
      expect(page).to have_css('table[aria-label="Pinned APOs"]')
      expect(page).to have_css('table[aria-label="Pinned virtual objects"]')
    end
  end

  context 'when signed in as a user with edit permission' do
    let(:workgroup) { 'sdr:test-workgroup' }

    before do
      create(:permission, :edit, workgroup:)
      sign_in(create(:user, groups: [workgroup]))
    end

    it 'enables the Item button' do
      visit root_path

      expect(page).to have_link('Item', href: new_item_path)
      expect(page).to have_no_css('a.disabled', text: 'Item')
    end
  end

  context 'when signed in as an admin user' do
    before { sign_in(create(:user, :admin)) }

    it 'displays the admin button list' do
      visit root_path

      expect(page).to have_css('h2', text: 'Admin')
      expect(page).to have_button('Manage permissions', class: 'disabled')
      expect(page).to have_link('Impersonate', href: admin_impersonate_path)
    end
  end

  context 'when the user has pinned items' do
    let(:user) { create(:user) }

    let(:pinned_druid) { 'druid:bc123df4567' }
    let(:other_pinned_druid) { 'druid:cd456fg7890' }
    let(:collection_druid) { 'druid:df567gh8901' }
    let(:other_collection_druid) { 'druid:fh678hj9012' }
    let(:apo_druid) { 'druid:fg789jm0123' }
    let(:other_apo_druid) { 'druid:gh890jk1234' }

    let(:solr_docs) do
      {
        pinned_druid => {
          Search::Fields::ID => pinned_druid,
          Search::Fields::TITLE => 'The pinned item title',
          Search::Fields::OBJECT_TYPES => ['item'],
          Search::Fields::COLLECTION_DRUIDS => [collection_druid],
          Search::Fields::COLLECTION_TITLES => ['The pinned item collection'],
          Search::Fields::APO_DRUID => apo_druid,
          Search::Fields::APO_TITLE => ['The pinned item APO']
        },
        other_pinned_druid => {
          Search::Fields::ID => other_pinned_druid,
          Search::Fields::TITLE => 'The other pinned item title',
          Search::Fields::OBJECT_TYPES => ['item'],
          Search::Fields::COLLECTION_DRUIDS => [other_collection_druid],
          Search::Fields::COLLECTION_TITLES => ['The other pinned item collection'],
          Search::Fields::APO_DRUID => other_apo_druid,
          Search::Fields::APO_TITLE => ['The other pinned item APO']
        }
      }
    end

    before do
      create(:pinned_object, user:, druid: pinned_druid)
      create(:pinned_object, user:, druid: other_pinned_druid)

      sign_in(user)

      allow(Searchers::ItemByDruid).to receive(:call) do |druids:, **|
        druids.map { |druid| SearchResults::Item.new(solr_doc: solr_docs.fetch(druid)) }
      end
    end

    it 'displays the pinned items in the Pinned items table and allows user to unpin' do
      visit root_path

      within('table[aria-label="Pinned items"]') do
        expect(page).to have_css('tr', text: 'The pinned item title')
        expect(page).to have_text('bc123df4567')
        expect(page).to have_text('The pinned item collection')
        expect(page).to have_text('The pinned item APO')

        expect(page).to have_css('tr', text: 'The other pinned item title')
        expect(page).to have_text('cd456fg7890')
      end

      # Unpin
      within('table[aria-label="Pinned items"]') do
        find('tr', text: 'The pinned item title').click_button
      end

      expect(page).to have_no_css('table[aria-label="Pinned items"] tr', text: 'The pinned item title')
      expect(page).to have_css('table[aria-label="Pinned items"] tr', text: 'The other pinned item title')

      # Unpin the other
      within('table[aria-label="Pinned items"]') do
        find('tr', text: 'The other pinned item title').click_button
      end

      expect(page).to have_no_css('table[aria-label="Pinned items"] tbody tr')
      expect(page).to have_text('No items have been pinned.')
    end
  end

  context 'when the user has pinned collections' do
    let(:user) { create(:user) }

    let(:pinned_druid) { 'druid:bc123df4567' }
    let(:other_pinned_druid) { 'druid:cd456fg7890' }
    let(:apo_druid) { 'druid:fg789jm0123' }
    let(:other_apo_druid) { 'druid:gh890jk1234' }

    let(:solr_docs) do
      {
        pinned_druid => {
          Search::Fields::ID => pinned_druid,
          Search::Fields::TITLE => 'The pinned collection title',
          Search::Fields::OBJECT_TYPES => ['collection'],
          Search::Fields::APO_DRUID => apo_druid,
          Search::Fields::APO_TITLE => ['The pinned collection APO']
        },
        other_pinned_druid => {
          Search::Fields::ID => other_pinned_druid,
          Search::Fields::TITLE => 'The other pinned collection title',
          Search::Fields::OBJECT_TYPES => ['collection'],
          Search::Fields::APO_DRUID => other_apo_druid,
          Search::Fields::APO_TITLE => ['The other pinned collection APO']
        }
      }
    end

    before do
      create(:pinned_object, user:, druid: pinned_druid)
      create(:pinned_object, user:, druid: other_pinned_druid)

      sign_in(user)

      allow(Searchers::ItemByDruid).to receive(:call) do |druids:, **|
        druids.map { |druid| SearchResults::Item.new(solr_doc: solr_docs.fetch(druid)) }
      end
    end

    it 'displays the pinned collections in the Pinned collections table and allows user to unpin' do
      visit root_path

      within('table[aria-label="Pinned collections"]') do
        expect(page).to have_css('tr', text: 'The pinned collection title')
        expect(page).to have_text('bc123df4567')
        expect(page).to have_text('The pinned collection APO')

        expect(page).to have_css('tr', text: 'The other pinned collection title')
        expect(page).to have_text('cd456fg7890')
      end

      # Unpin
      within('table[aria-label="Pinned collections"]') do
        find('tr', text: 'The pinned collection title').click_button
      end

      expect(page).to have_no_css('table[aria-label="Pinned collections"] tr', text: 'The pinned collection title')
      expect(page).to have_css('table[aria-label="Pinned collections"] tr', text: 'The other pinned collection title')

      # Unpin the other
      within('table[aria-label="Pinned collections"]') do
        find('tr', text: 'The other pinned collection title').click_button
      end

      expect(page).to have_no_css('table[aria-label="Pinned collections"] tbody tr')
      expect(page).to have_text('No collections have been pinned.')
    end
  end

  context 'when the user has pinned APOs' do
    let(:user) { create(:user) }

    let(:pinned_druid) { 'druid:bc123df4567' }
    let(:other_pinned_druid) { 'druid:cd456fg7890' }
    let(:agreement_druid) { 'druid:fg789jm0123' }
    let(:other_agreement_druid) { 'druid:gh890jk1234' }

    let(:solr_docs) do
      {
        pinned_druid => {
          Search::Fields::ID => pinned_druid,
          Search::Fields::TITLE => 'The pinned APO title',
          Search::Fields::OBJECT_TYPES => ['APO'],
          Search::Fields::AGREEMENT_DRUID => agreement_druid,
          Search::Fields::AGREEMENT_TITLE => 'The pinned APO agreement'
        },
        other_pinned_druid => {
          Search::Fields::ID => other_pinned_druid,
          Search::Fields::TITLE => 'The other pinned APO title',
          Search::Fields::OBJECT_TYPES => ['APO'],
          Search::Fields::AGREEMENT_DRUID => other_agreement_druid,
          Search::Fields::AGREEMENT_TITLE => 'The other pinned APO agreement'
        }
      }
    end

    before do
      create(:pinned_object, user:, druid: pinned_druid)
      create(:pinned_object, user:, druid: other_pinned_druid)

      sign_in(user)

      allow(Searchers::ItemByDruid).to receive(:call) do |druids:, **|
        druids.map { |druid| SearchResults::Item.new(solr_doc: solr_docs.fetch(druid)) }
      end
    end

    it 'displays the pinned APOs in the Pinned APOs table and allows user to unpin' do
      visit root_path

      within('table[aria-label="Pinned APOs"]') do
        expect(page).to have_css('tr', text: 'The pinned APO title')
        expect(page).to have_text('bc123df4567')
        expect(page).to have_text('The pinned APO agreement')

        expect(page).to have_css('tr', text: 'The other pinned APO title')
        expect(page).to have_text('cd456fg7890')
      end

      # Unpin
      within('table[aria-label="Pinned APOs"]') do
        find('tr', text: 'The pinned APO title').click_button
      end

      expect(page).to have_no_css('table[aria-label="Pinned APOs"] tr', text: 'The pinned APO title')
      expect(page).to have_css('table[aria-label="Pinned APOs"] tr', text: 'The other pinned APO title')

      # Unpin the other
      within('table[aria-label="Pinned APOs"]') do
        find('tr', text: 'The other pinned APO title').click_button
      end

      expect(page).to have_no_css('table[aria-label="Pinned APOs"] tbody tr')
      expect(page).to have_text('No APOs have been pinned.')
    end
  end

  context 'when the user has pinned virtual objects' do
    let(:user) { create(:user) }

    let(:pinned_druid) { 'druid:bc123df4567' }
    let(:other_pinned_druid) { 'druid:cd456fg7890' }
    let(:collection_druid) { 'druid:df567gh8901' }
    let(:other_collection_druid) { 'druid:fh678hj9012' }
    let(:apo_druid) { 'druid:fg789jm0123' }
    let(:other_apo_druid) { 'druid:gh890jk1234' }

    let(:solr_docs) do
      {
        pinned_druid => {
          Search::Fields::ID => pinned_druid,
          Search::Fields::TITLE => 'The pinned virtual object title',
          Search::Fields::OBJECT_TYPES => ['virtual object'],
          Search::Fields::COLLECTION_DRUIDS => [collection_druid],
          Search::Fields::COLLECTION_TITLES => ['The pinned virtual object collection'],
          Search::Fields::APO_DRUID => apo_druid,
          Search::Fields::APO_TITLE => ['The pinned virtual object APO'],
          Search::Fields::CONSTITUENTS_COUNT => 3
        },
        other_pinned_druid => {
          Search::Fields::ID => other_pinned_druid,
          Search::Fields::TITLE => 'The other pinned virtual object title',
          Search::Fields::OBJECT_TYPES => ['virtual object'],
          Search::Fields::COLLECTION_DRUIDS => [other_collection_druid],
          Search::Fields::COLLECTION_TITLES => ['The other pinned virtual object collection'],
          Search::Fields::APO_DRUID => other_apo_druid,
          Search::Fields::APO_TITLE => ['The other pinned virtual object APO'],
          Search::Fields::CONSTITUENTS_COUNT => 5
        }
      }
    end

    before do
      create(:pinned_object, user:, druid: pinned_druid)
      create(:pinned_object, user:, druid: other_pinned_druid)

      sign_in(user)

      allow(Searchers::ItemByDruid).to receive(:call) do |druids:, **|
        druids.map { |druid| SearchResults::Item.new(solr_doc: solr_docs.fetch(druid)) }
      end
    end

    it 'displays the pinned virtual objects in the Pinned virtual objects table and allows user to unpin' do
      visit root_path

      within('table[aria-label="Pinned virtual objects"]') do
        expect(page).to have_css('tr', text: 'The pinned virtual object title')
        expect(page).to have_text('bc123df4567')
        expect(page).to have_text('The pinned virtual object collection')
        expect(page).to have_text('The pinned virtual object APO')
        expect(page).to have_text('3')

        expect(page).to have_css('tr', text: 'The other pinned virtual object title')
        expect(page).to have_text('cd456fg7890')
      end

      # Unpin
      within('table[aria-label="Pinned virtual objects"]') do
        find('tr', text: 'The pinned virtual object title').click_button
      end

      expect(page).to have_no_css('table[aria-label="Pinned virtual objects"] tr',
                                  text: 'The pinned virtual object title')
      expect(page).to have_css('table[aria-label="Pinned virtual objects"] tr',
                               text: 'The other pinned virtual object title')

      # Unpin the other
      within('table[aria-label="Pinned virtual objects"]') do
        find('tr', text: 'The other pinned virtual object title').click_button
      end

      expect(page).to have_no_css('table[aria-label="Pinned virtual objects"] tbody tr')
      expect(page).to have_text('No virtual objects have been pinned.')
    end
  end
end
