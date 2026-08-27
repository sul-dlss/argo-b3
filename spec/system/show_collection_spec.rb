# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show collection' do
  let(:druid) { 'druid:bb123cd4567' }
  let(:apo_druid) { 'druid:cc123cd4578' }

  let(:original_title) { 'My collection title' }
  let(:updated_title) { 'My updated collection title' }

  # Versions are tested in show_dro_spec so returning [].
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, milestones: milestones_client,
                                                   release_tags: release_tags_client,
                                                   user_version: user_version_client, lock: 'lock1')
  end
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: [], status: version_status) }
  let(:version_status) do
    instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, accessioning?: false, closed?: false)
  end
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: []) }
  let(:milestones_client) { instance_double(Dor::Services::Client::Milestones, list: []) }
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: []) }

  def build_solr_doc(title:)
    {
      Search::Fields::ID => druid,
      Search::Fields::OBJECT_TYPES => ['collection'],
      Search::Fields::TITLE => title,
      Search::Fields::APO_DRUID => [apo_druid],
      Search::Fields::APO_TITLE => ['My APO'],
      Search::Fields::SOURCE_ID => 'googlebooks:stanford_36105114203446',
      Search::Fields::CATALOG_RECORD_ID => ['a6525053'],
      Search::Fields::OTHER_TAGS => ['Registered By : jdoe', 'Remediated By : labtech', 'Ticket : TESTREQ-1'],
      Search::Fields::TICKETS => ['TESTREQ-1']
    }
  end

  def build_cocina_object(title:, access: {})
    build(:collection_with_metadata, id: druid, admin_policy_id: apo_druid)
      .new(
        description: {
          title: [{ value: title }],
          purl: 'https://purl.stanford.edu/bb123cd4567'
        },
        access:
      )
  end

  before do
    create(:permission, :read_unrestricted, workgroup: 'sdr:argo-access')

    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([]) # Workflows are tested in show_dro_spec.
    allow(PurlPreviewService).to receive(:call).and_return('<html><body><main><p>preview</p></main></body></html>')

    sign_in(create(:user))
  end

  it 'displays the collection' do
    # Defining the solr doc and cocina object inline because going to change the title to test refresh.
    allow(Sdr::Repository).to receive(:find_solr).and_return(build_solr_doc(title: original_title))
    allow(Sdr::Repository).to receive(:find).and_return(
      build_cocina_object(title: original_title, access: {
                            copyright: 'My copyright statement',
                            license: 'https://creativecommons.org/licenses/by/4.0/legalcode',
                            useAndReproductionStatement: 'My use statement'
                          })
    )

    visit "/objects/#{druid}"

    expect(page).to have_css('h1', text: original_title)
    expect(page).to have_css('.object-show.object-type-collection .object-type-badge', text: 'COLLECTION')

    # Status box
    expect(page).to have_css('h2', text: 'Draft, not deposited')

    # Released to box
    expect(page).to have_css('h2', text: 'Not released')

    # Tabs
    expect(page).to have_css('.nav-link.active', text: 'Overview')
    expect(page).to have_css('.nav-link', text: 'Workflows')
    expect(page).to have_css('.nav-link', text: 'Versions')
    expect(page).to have_css('.nav-link', text: 'Events')
    expect(page).to have_css('.nav-link', text: 'Cocina JSON')
    expect(page).to have_css('.nav-link', text: 'SOLR doc')
    expect(page).to have_css('.nav-link', text: 'Description preview')

    # PURL link in side nav
    expect(page).to have_link('View PURL page', href: "https://purl.stanford.edu/#{DruidSupport.bare_druid_from(druid)}")

    # Overview table
    expect(page).to have_css('table[id="overview-table"] caption', text: 'Overview')
    expect(page).to have_table_value('overview-table', 'Object type', 'Collection')
    within(find_table_value_cell('overview-table', 'Admin policy')) do
      expect(page).to have_link('My APO', href: "/objects/#{apo_druid}")
      expect(page).to have_link('All objects with this APO',
                                href: '/search?admin_policy_titles%5B%5D=My+APO&page=1')
    end

    # Identification table
    expect(page).to have_table_caption('identification-table', 'Identification')
    expect(page).to have_table_value('identification-table', 'Druid', druid)
    expect(page).to have_table_value('identification-table', 'Source ID', 'googlebooks:stanford_36105114203446')
    expect(page).to have_table_value('identification-table', 'Folio Instance HRID', 'a6525053')

    # Access table
    expect(page).to have_table_caption('access-table', 'Access')
    expect(page).to have_table_value('access-table', 'Access rights', 'View: Dark')
    expect(page).to have_table_value('access-table', 'Copyright', 'My copyright statement')
    expect(page).to have_table_value('access-table', 'License', 'https://creativecommons.org/licenses/by/4.0/legalcode')
    expect(page).to have_table_value('access-table', 'Use and reproduction', 'My use statement')

    # Tags card
    within('.card', text: 'Tags') do
      expect(page).to have_css('li', text: 'Ticket : TESTREQ-1')
      expect(page).to have_css('li', text: 'Registered By : jdoe')
      expect(page).to have_css('li', text: 'Remediated By : labtech')
    end

    # Cocina model tab
    click_button 'Cocina JSON'
    # andypf-json-viewer uses a shadow DOM, so can't check for content within it.
    expect(page).to have_css('andypf-json-viewer', text: 'druid')
    expect(page).to have_css('andypf-json-viewer', text: original_title)

    # PURL preview tab
    click_button 'Description preview'
    expect(page).to have_css('p', text: 'preview')
    expect(page).to have_link('View PURL page',
                              href: "https://purl.stanford.edu/#{DruidSupport.bare_druid_from(druid)}", count: 2)

    allow(Sdr::Repository).to receive(:find_solr).and_return(build_solr_doc(title: updated_title))
    allow(Sdr::Repository).to receive(:find)
      .and_return(build_cocina_object(title: updated_title, access: {
                                        view: 'world',
                                        copyright: 'My updated copyright statement',
                                        license: 'https://creativecommons.org/publicdomain/zero/1.0/legalcode',
                                        useAndReproductionStatement: 'My updated use statement'
                                      }))

    expect(page).to have_css('h1', text: updated_title)

    click_button 'Overview'
    expect(page).to have_table_value('access-table', 'Access rights', 'View: World')
    expect(page).to have_table_value('access-table', 'Copyright', 'My updated copyright statement')
    expect(page).to have_table_value('access-table', 'License', 'https://creativecommons.org/publicdomain/zero/1.0/legalcode')
    expect(page).to have_table_value('access-table', 'Use and reproduction', 'My updated use statement')

    click_button 'Cocina JSON'
    expect(page).to have_css('andypf-json-viewer', text: updated_title)
  end
end
