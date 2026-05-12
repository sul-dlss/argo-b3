# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show DRO' do
  let(:druid) { 'druid:bb123cd4567' }
  let(:apo_druid) { 'druid:cc123cd4578' }
  let(:collection_druid) { 'druid:dd123cd4589' }

  let(:original_title)  { 'My title' }
  let(:updated_title)   { 'My updated title' }

  let(:registration_workflow) do
    xml = <<~XML
      <workflow id="registrationWF">
        <process version="1" note="" lifecycle="registered" laneId="low" elapsed="" attempts="0" datetime="2022-04-18T08:32:40+00:00" context="" status="completed" name="register"/>
      </workflow>
    XML
    Dor::Services::Response::Workflow.new(xml:)
  end

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, milestones: milestones_client,
                                                   user_version: user_version_client)
  end
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: version_inventory) }
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: user_version_inventory) }
  let(:milestones_client) { instance_double(Dor::Services::Client::Milestones, list: milestones) }

  let(:version_inventory) do
    [
      Dor::Services::Client::ObjectVersion::Version.new(versionId: 1, message: 'Initial version', cocina: true),
      Dor::Services::Client::ObjectVersion::Version.new(versionId: 2, message: 'Second version', cocina: true)
    ]
  end

  let(:user_version_inventory) do
    [
      Dor::Services::Client::UserVersion::Version.new(version: 2, userVersion: 1)
    ]
  end

  let(:milestones) do
    [
      { milestone: 'registered', at: '2020-02-28 20:23:30 +0000', version: '1' },
      { milestone: 'submitted', at: '2020-02-28 20:23:35 +0000', version: '1' },
      { milestone: 'described', at: '2020-02-28 20:57:36 +0000', version: '1' },
      { milestone: 'published', at: '2020-02-28 21:01:20 +0000', version: '1' },
      { milestone: 'deposited', at: '2020-02-28 21:01:51 +0000', version: '1' },
      { milestone: 'accessioned', at: '2020-02-28 21:02:03 +0000', version: '1' },
      { milestone: 'opened', at: '2021-03-31 20:23:30 +0000', version: '2' },
      { milestone: 'submitted', at: '2021-03-31 20:23:35 +0000', version: '2' },
      { milestone: 'described', at: '2021-03-31 20:57:36 +0000', version: '2' },
      { milestone: 'published', at: '2021-03-31 21:01:20 +0000', version: '2' },
      { milestone: 'deposited', at: '2021-03-31 21:01:51 +0000', version: '2' },
      { milestone: 'accessioned', at: '2021-03-31 21:02:03 +0000', version: '2' }
    ]
  end

  def build_solr_doc(title:)
    {
      Search::Fields::ID => druid,
      Search::Fields::OBJECT_TYPES => ['item'],
      Search::Fields::TITLE => title,
      Search::Fields::APO_DRUID => [apo_druid],
      Search::Fields::APO_TITLE => ['My APO'],
      Search::Fields::COLLECTION_DRUIDS => [collection_druid],
      Search::Fields::COLLECTION_TITLES => ['My Collection'],
      Search::Fields::FIRST_SHELVED_IMAGE => 'rr624wq8610_00_0001.jp2',
      Search::Fields::SOURCE_ID => 'googlebooks:stanford_36105114203446',
      Search::Fields::CATALOG_RECORD_ID => ['a6525053'],
      Search::Fields::BARCODES => ['bb123cd4567'],
      Search::Fields::DOI => 'https://doi.org/10.5072/bb123cd4567'
    }
  end

  def build_cocina_object(title:)
    build(:dro_with_metadata, id: druid, admin_policy_id: apo_druid)
      .new(
        structural: { isMemberOf: [collection_druid] },
        description: {
          title: [{ value: title }],
          purl: 'https://purl.stanford.edu/bb123cd4567'
        }
      )
  end

  def build_accession_workflow(complete: false) # rubocop:disable Metrics/MethodLength
    xml = <<~XML
      <workflow id="accessionWF">
        <process version="1" note="" lifecycle="submitted" laneId="low" elapsed="" attempts="0" datetime="2023-06-21T17:36:18+00:00" context="" status="completed" name="start-accession"/>
        <process version="1" note="No descMetadata.xml was provided" lifecycle="described" laneId="low" elapsed="0.102" attempts="0" datetime="2023-06-21T17:36:18+00:00" context="" status="skipped" name="descriptive-metadata"/>
        <process version="1" note="No contentMetadata.xml was provided" lifecycle="" laneId="low" elapsed="0.551" attempts="0" datetime="2023-06-21T17:36:18+00:00" context="" status="skipped" name="content-metadata"/>
        <process version="1" note="Completed by technical-metadata-service on dor-techmd-worker-prod-a.stanford.edu." lifecycle="" laneId="low" elapsed="1.525" attempts="0" datetime="2023-06-21T17:36:18+00:00" context="" status="completed" name="technical-metadata"/>
        <process version="1" note="Completed Job 10476358 on dor-services-app" lifecycle="" laneId="low" elapsed="1.0" attempts="0" datetime="2023-06-21T17:36:18+00:00" context="" status="completed" name="shelve"/>
        <process version="1" note="Completed Job 10476361 on dor-services-app" lifecycle="published" laneId="low" elapsed="1.0" attempts="0" datetime="2023-06-21T17:36:18+00:00" context="" status="completed" name="publish"/>
        <process version="1" note="Object does not have a DOI" lifecycle="" laneId="low" elapsed="0.405" attempts="0" datetime="2023-06-21T17:36:18+00:00" context="" status="skipped" name="update-doi"/>
        <process version="1" note="Completed Job 10476363 on dor-services-app" lifecycle="" laneId="low" elapsed="1.0" attempts="0" datetime="2023-06-21T17:36:18+00:00" context="" status="completed" name="sdr-ingest-transfer"/>
        <process version="1" note="preservationIngestWF completed on preservation-robots1-prod.stanford.edu" lifecycle="deposited" laneId="low" elapsed="1.0" attempts="0" datetime="2023-06-21T17:36:18+00:00" context="" status="completed" name="sdr-ingest-received"/>
        <process version="1" note="common-accessioning-prod-c.stanford.edu" lifecycle="" laneId="low" elapsed="0.37" attempts="0" datetime="2023-06-21T17:36:18+00:00" context="" status="completed" name="reset-workspace"/>
        <process version="1" note="common-accessioning-prod-c.stanford.edu" lifecycle="accessioned" laneId="low" elapsed="1.454" attempts="0" datetime="2023-06-21T17:36:18+00:00" context="" status="completed" name="end-accession"/>
        <process version="2" note="" lifecycle="submitted" laneId="default" elapsed="" attempts="0" datetime="2023-06-21T17:36:18+00:00" context="" status="completed" name="start-accession"/>
        <process version="2" note="No descMetadata.xml was provided" lifecycle="described" laneId="default" elapsed="0.008" attempts="0" datetime="2023-06-21T17:36:19+00:00" context="" status="skipped" name="descriptive-metadata"/>
        <process version="2" note="No contentMetadata.xml was provided" lifecycle="" laneId="default" elapsed="0.102" attempts="0" datetime="2023-06-21T17:36:19+00:00" context="" status="skipped" name="content-metadata"/>
        <process version="2" note="change is metadata-only" lifecycle="" laneId="default" elapsed="0.102" attempts="0" datetime="2023-06-21T17:36:19+00:00" context="" status="skipped" name="technical-metadata"/>
        <process version="2" note="Completed Job 21618100 on dor-services-app" lifecycle="" laneId="default" elapsed="1.0" attempts="0" datetime="2023-06-21T17:36:20+00:00" context="" status="completed" name="shelve"/>
        <process version="2" note="Completed Job 21618111 on dor-services-app" lifecycle="published" laneId="default" elapsed="1.0" attempts="0" datetime="2023-06-21T17:36:21+00:00" context="" status="completed" name="publish"/>
        <process version="2" note="Object does not have a DOI" lifecycle="" laneId="default" elapsed="0.111" attempts="0" datetime="2023-06-21T17:36:22+00:00" context="" status="skipped" name="update-doi"/>
        <process version="2" note="Completed Job 21618118 on dor-services-app" lifecycle="" laneId="default" elapsed="1.0" attempts="0" datetime="2023-06-21T17:36:23+00:00" context="" status="completed" name="sdr-ingest-transfer"/>
        <process version="2" note="" errorMessage="#{'Bag validation failed' unless complete}" lifecycle="deposited" laneId="default" elapsed="1.0" attempts="0" datetime="2023-06-21T17:36:27+00:00" context="" status="#{complete ? 'completed' : 'error'}" name="sdr-ingest-received"/>
        <process version="2" note="" lifecycle="" laneId="default" elapsed="0.197" attempts="0" datetime="2023-06-21T17:36:27+00:00" context="" status="#{complete ? 'completed' : 'started'}" name="reset-workspace"/>
        <process version="2" note="" lifecycle="accessioned" laneId="default" elapsed="1.0" attempts="0" datetime="2023-06-21T17:36:28+00:00" context="" status="#{complete ? 'completed' : 'waiting'}" name="end-accession"/>
      </workflow>
    XML
    Dor::Services::Response::Workflow.new(xml:)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(PurlPreviewService).to receive(:call).and_return('<html><body><main><p>preview</p></main></body></html>')

    sign_in(create(:user))
    set_last_search_cookie
  end

  it 'displays the object' do
    # Defining the solr doc and cocina object inline because going to change the title to test refresh.
    allow(Sdr::Repository).to receive(:find_solr).and_return(build_solr_doc(title: original_title))
    allow(Sdr::Repository).to receive(:find).and_return(build_cocina_object(title: original_title))
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([registration_workflow,
                                                                       build_accession_workflow])

    visit "/objects/#{druid}"

    expect(page).to have_css('h1', text: original_title)

    expect(page).to have_link('← Back to search', href: /search\?page=5&query=test/)

    # Tabs
    expect(page).to have_css('.nav-link.active', text: 'Details')
    expect(page).to have_css('.nav-link', text: 'Workflows')
    expect(page).to have_css('.nav-link', text: 'Versions')
    expect(page).to have_css('.nav-link', text: 'Events')
    expect(page).to have_css('.nav-link', text: 'Content')
    expect(page).to have_css('.nav-link', text: 'Technical metadata')
    expect(page).to have_css('.nav-link', text: 'Cocina Model')
    expect(page).to have_css('.nav-link', text: 'PURL Description Preview')

    # Overview table
    expect(page).to have_table_caption('overview-table', 'Overview')
    expect(page).to have_table_value('overview-table', 'Object type', 'Item')
    within(find_table_value_cell('overview-table', 'Admin policy')) do
      expect(page).to have_link('My APO', href: "/objects/#{apo_druid}")
      expect(page).to have_link('All objects with this APO',
                                href: '/search?admin_policy_titles%5B%5D=My+APO&page=1')
    end
    within(find_table_value_cell('overview-table', 'Collection')) do
      expect(page).to have_link('My Collection', href: "/objects/#{collection_druid}")
      expect(page).to have_link('All objects with this collection',
                                href: '/search?collection_titles%5B%5D=My+Collection&page=1')
    end

    # Thumbnail
    expect(page).to have_css('img.thumbnail[src="http://stacks.stanford.edu/image/iiif/bb123cd4567%2Frr624wq8610_00_0001/full/!400,400/0/default.jpg"]') # rubocop:disable Layout/LineLength

    # Description table
    expect(page).to have_table_caption('description-table', 'Description')
    expect(page).to have_css('table[id="description-table"] caption', text: 'Description')
    expect(page).to have_table_value('description-table', 'Title', original_title)

    # Identification table
    expect(page).to have_table_caption('identification-table', 'Identification')
    expect(page).to have_table_value('identification-table', 'Druid', druid)
    expect(page).to have_table_value('identification-table', 'Source ID', 'googlebooks:stanford_36105114203446')
    expect(page).to have_table_value('identification-table', 'Folio Instance HRID', 'a6525053')
    expect(page).to have_table_value('identification-table', 'Barcode', 'bb123cd4567')
    expect(page).to have_table_value('identification-table', 'DOI', 'https://doi.org/10.5072/bb123cd4567')

    # Cocina model tab
    click_button 'Cocina Model'
    # andypf-json-viewer uses a shadow DOM, so can't check for content within it.
    expect(page).to have_css("andypf-json-viewer[data*='#{druid}']")
    expect(page).to have_css("andypf-json-viewer[data*='#{original_title}']")

    # Workflows tab
    click_button 'Workflows'
    expect(page).to have_css('.accordion-item', count: 2)
    expect(page).to have_css('.accordion-button.collapsed', text: 'registrationWF')
    expect(page).to have_css('.accordion-button.collapsed .badge', text: 'Complete')
    expect(page).to have_css('.accordion-button:not(.collapsed)', text: 'accessionWF')
    expect(page).to have_css('.accordion-button:not(.collapsed) .badge', text: 'In progress')

    within('#accessionwf-collapse.accordion-collapse.show') do
      expect(page).to have_table(count: 2)
      expect(page).to have_table_caption('accessionwf-2-table', 'accessionWF - Version 2')
      expect(page).to have_table_caption('accessionwf-1-table', 'accessionWF - Version 1')

      row = find_table_row('accessionwf-2-table', 'descriptive-metadata')
      expect(row).to have_css('th', text: 'descriptive-metadata')
      cells = row.all('td')
      expect(cells[0]).to have_text('described')
      expect(cells[1]).to have_text('skipped')
      expect(cells[2]).to have_text('June 21, 2023 10:36')
      expect(cells[3]).to have_text('less than a minute')
      expect(page).to have_css('td.text-success-emphasis', text: 'Note: No descMetadata.xml was provided')

      row = find_table_row('accessionwf-2-table', 'sdr-ingest-received')
      cells = row.all('td')
      expect(cells[0]).to have_text('deposited')
      expect(cells[1]).to have_text('error')
      expect(page).to have_css('td.text-danger', text: 'Error: Bag validation failed')
    end

    # Collapse accessionWF and expand registrationWF.
    click_button 'accessionWF'
    expect(page).to have_no_css('#accessionwf-collapse')
    click_button 'registrationWF'
    within('#registrationwf-collapse.accordion-collapse.show') do
      expect(page).to have_table(count: 1)
    end

    # Versions tab
    click_button 'Versions'

    within(find_table('versions-table')) do
      expect(page).to have_css('th', text: 'Version')
      expect(page).to have_css('th', text: 'Description')
      expect(page).to have_css('th', text: 'User Version')
      expect(page).to have_css('th', text: 'Registered / opened')
      expect(page).to have_css('th', text: 'Submitted')
      expect(page).to have_css('th', text: 'Accessioned')
    end

    row = find_table_row('versions-table', '1')
    cells = row.all('td')
    expect(cells[0]).to have_text('Initial version')
    expect(cells[1]).to have_text('')
    expect(cells[2]).to have_text('February 28, 2020 12:23 PM')
    expect(cells[3]).to have_text('February 28, 2020 12:23 PM')
    expect(cells[4]).to have_text('February 28, 2020 01:02 PM')

    row = find_table_row('versions-table', '2')
    cells = row.all('td')
    expect(cells[0]).to have_text('Second version')
    expect(cells[1]).to have_text('1')
    expect(cells[2]).to have_text('March 31, 2021 01:23 PM')
    expect(cells[3]).to have_text('March 31, 2021 01:23 PM')
    expect(cells[4]).to have_text('March 31, 2021 02:02 PM')

    # PURL preview tab
    click_button 'PURL Description Preview'
    expect(page).to have_css('p', text: 'preview')

    # Update the object and look for changes.
    allow(Sdr::Repository).to receive(:find_solr).and_return(build_solr_doc(title: updated_title))
    allow(Sdr::Repository).to receive(:find).and_return(build_cocina_object(title: updated_title))
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([registration_workflow,
                                                                       build_accession_workflow(complete: true)])

    expect(page).to have_css('h1', text: updated_title, wait: 15)
    click_button 'Cocina Model'
    expect(page).to have_css("andypf-json-viewer[data*='#{updated_title}']")

    click_button 'Details'
    expect(page).to have_table_value('description-table', 'Title', updated_title)

    click_button 'Workflows'
    expect(page).to have_css('.accordion-item',
                             count: 2)
    expect(page).to have_css('.accordion-button:not(.collapsed)', text: 'registrationWF')
    expect(page).to have_css('.accordion-button:not(.collapsed) .badge', text: 'Complete')
    expect(page).to have_css('.accordion-button.collapsed', text: 'accessionWF')
    expect(page).to have_css('.accordion-button.collapsed .badge', text: 'Complete')

    click_button 'accessionWF'

    within('#accessionwf-collapse.accordion-collapse.show') do
      row = find_table_row('accessionwf-2-table', 'sdr-ingest-received')
      cells = row.all('td')
      expect(cells[1]).to have_text('completed')
      expect(page).to have_no_css('td.text-danger', text: 'Error: Bag validation failed')
    end
  end
end
