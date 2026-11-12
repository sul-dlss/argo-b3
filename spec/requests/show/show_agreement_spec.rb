# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show agreement' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bb123cd4567' }
  let(:apo_druid) { 'druid:cc123cd4578' }
  let(:title) { 'My agreement title' }

  # Versions and workflows are tested in show_dro_spec, so returning minimal/empty values here.

  let(:version_status) do
    instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, assembling?: false, accessioning?: true,
                                                                         closed?: true)
  end

  let(:solr_doc) do
    {
      Search::Fields::ID => druid,
      Search::Fields::OBJECT_TYPES => ['agreement'],
      Search::Fields::CONTENT_TYPES => ['agreement'],
      Search::Fields::TITLE => title,
      Search::Fields::APO_DRUID => [apo_druid],
      Search::Fields::APO_TITLE => ['My APO'],
      Search::Fields::COLLECTION_DRUIDS => [],
      Search::Fields::COLLECTION_TITLES => []
    }
  end

  let(:cocina_object) do
    build(:agreement_with_metadata, id: druid, admin_policy_id: apo_druid, title:)
  end

  before do
    create(:permission, :read_unrestricted, workgroup: 'sdr:argo-access')

    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
    allow(Sdr::Repository).to receive_messages(find_solr: solr_doc, find: cocina_object)

    sign_in(create(:user))
  end

  it 'displays the agreement' do
    get "/objects/#{druid}"

    expect(response).to have_http_status(:ok)
    rendered_page = Capybara.string(response.body)
    expect(rendered_page).to have_css('h1', text: title)
    expect(rendered_page).to have_css('.object-show.object-type-agreement .object-type-badge', text: /agreement/i)

    # Agreements are dark
    expect(rendered_page).to have_no_link('View PURL page')
    expect(rendered_page).to have_no_button('Republish')
    expect(rendered_page).to have_no_button('Register & deposit collection')
    expect(rendered_page).to have_no_css('h2', text: 'Released to')
    expect(rendered_page).to have_no_css('h2', text: 'Not released')

    # Tabs
    expect(rendered_page).to have_css('.nav-link', text: 'Files')
    expect(rendered_page).to have_css('.nav-link', text: 'Structure')
    expect(rendered_page).to have_css('.nav-link', text: 'Workflows')
    expect(rendered_page).to have_css('.nav-link', text: 'Versions')
    expect(rendered_page).to have_no_css('.nav-link', text: 'Description preview')
    expect(rendered_page).to have_no_css('.nav-link', text: 'Constituents')
    expect(rendered_page).to have_no_css('.nav-link', text: 'Technical metadata')
    expect(rendered_page).to have_css('#files-pane')
    expect(rendered_page).to have_css('#structure-pane')

    # No pin
    expect(rendered_page).to have_no_css('.bi-pin')
    expect(rendered_page).to have_no_css('.bi-pin-fill')

    # Events tab (events are lazily loaded; see show_events_spec)
    expect(rendered_page).to have_css('.nav-link', text: 'Events')
    expect(rendered_page).to have_css('#events-pane turbo-frame[src*="/events"]')
  end

  describe 'GET /objects/:druid/overview' do
    let(:admin_policy_count) { 1234 }
    let(:token) do
      Rails.application.message_verifier(:argo).generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
    end

    before do
      allow(Search::SolrService).to receive(:post).and_return({ 'response' => { 'numFound' => admin_policy_count } })
    end

    it 'links to a search for the APOs with the agreement' do
      get "/objects/#{token}/overview"

      expect(response).to have_http_status(:ok)
      rendered_page = Capybara.string(response.body)
      apo_count_row = rendered_page.find('#apo-collection-rights-table tr', text: 'APOs with agreement')
      expect(apo_count_row).to have_link('View 1234 APOs', href: '/search?agreement_druids%5B%5D=druid%3Abb123cd4567')
      expect(Search::SolrService).to have_received(:post)
        .with(request: hash_including(q: 'agreement_ssi:"druid:bb123cd4567"', rows: 0))
    end
  end
end
