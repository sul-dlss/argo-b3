# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Header dropdowns on pages that refresh themselves' do
  let(:user) { create(:user) }
  let(:toggle) { find('header button.dropdown-toggle', text: 'Bulk actions') }
  let(:menu) { toggle.find(:xpath, 'following-sibling::ul[contains(@class, "dropdown-menu")]', visible: :all) }

  # Waits for the page to be morph refreshed: by its own refresh timer, or else started here.
  # The marker is not in the server-rendered page, so a morph removes it.
  def wait_for_refresh(start: true)
    page.execute_script("document.body.dataset.refreshMarker = 'true'")
    page.execute_script('Turbo.session.refresh(window.location.href)') if start
    expect(page).to have_no_css('body[data-refresh-marker]')
  end

  def expect_open
    expect(menu).to match_selector('.dropdown-menu.show', visible: :visible)
    expect(toggle).to match_selector('[aria-expanded="true"]')
  end

  def expect_closed
    expect(menu).to match_selector('.dropdown-menu:not(.show)', visible: :hidden)
    expect(toggle).to match_selector('[aria-expanded="false"]')
  end

  before { sign_in(user) }

  context 'when on an object show page' do
    include_context 'with show page object client'

    let(:druid) { 'druid:bb123cd4567' }
    let(:apo_druid) { 'druid:cc123cd4578' }

    before do
      create(:permission, :read_unrestricted, workgroup: 'sdr:argo-access')

      allow(Sdr::Repository).to receive_messages(
        find_solr: {
          Search::Fields::ID => druid,
          Search::Fields::OBJECT_TYPES => ['collection'],
          Search::Fields::TITLE => 'My collection',
          Search::Fields::APO_DRUID => [apo_druid],
          Search::Fields::APO_TITLE => ['My APO']
        },
        find: build(:collection_with_metadata, id: druid, admin_policy_id: apo_druid, title: 'My collection')
      )
      allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
      allow(PurlPreviewService).to receive(:call).and_return('<html><body><main><p>preview</p></main></body></html>')
      allow(Searchers::CollectionItemCount).to receive(:call).and_return(0)
    end

    it 'keeps an open dropdown open, and a closed one closed, across refreshes' do
      visit "/objects/#{druid}"
      expect(page).to have_css('h1', text: 'My collection')

      wait_for_refresh
      expect_closed

      toggle.click
      expect_open

      wait_for_refresh
      expect_open

      # The dropdown still closes and reopens normally.
      toggle.click
      expect_closed
      toggle.click
      expect_open

      # Escape still closes it, and a closed dropdown stays closed.
      toggle.send_keys(:escape)
      expect_closed
      wait_for_refresh
      expect_closed
    end
  end

  context 'when on a page that refreshes on a schedule' do
    let(:bulk_action) { create(:bulk_action, user:, action_type: 'export_cocina_json', description: 'My bulk action') }

    it 'keeps an open dropdown open across scheduled refreshes' do
      visit bulk_action_path(bulk_action)
      expect(page).to have_css('h2', text: 'Processing')

      toggle.click
      expect_open

      wait_for_refresh(start: false)
      expect_open

      toggle.click
      expect_closed
    end
  end
end
