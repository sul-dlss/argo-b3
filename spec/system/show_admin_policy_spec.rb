# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show admin policy' do
  let(:druid) { 'druid:bb123cd4567' }
  let(:apo_druid) { 'druid:cc123cd4578' }

  let(:original_title) { 'My admin policy title' }
  let(:updated_title) { 'My updated admin policy title' }

  # Versions are tested in show_dro_spec so returning [].
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, milestones: milestones_client,
                                                   user_version: user_version_client)
  end
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: []) }
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: []) }
  let(:milestones_client) { instance_double(Dor::Services::Client::Milestones, list: []) }

  def build_solr_doc(title:)
    {
      Search::Fields::ID => druid,
      Search::Fields::OBJECT_TYPES => ['admin_policy'],
      Search::Fields::TITLE => title,
      Search::Fields::APO_DRUID => [apo_druid],
      Search::Fields::APO_TITLE => ['My APO']
    }
  end

  def build_cocina_object(title:)
    build(:admin_policy_with_metadata, id: druid, admin_policy_id: apo_druid)
      .new(
        description: {
          title: [{ value: title }],
          purl: 'https://purl.stanford.edu/bb123cd4567'
        }
      )
  end

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([]) # Workflows are tested in show_dro_spec.

    sign_in(create(:user))
  end

  it 'displays the admin policy' do
    # Defining the solr doc and cocina object inline because going to change the title to test refresh.
    allow(Sdr::Repository).to receive(:find_solr).and_return(build_solr_doc(title: original_title))
    allow(Sdr::Repository).to receive(:find).and_return(build_cocina_object(title: original_title))

    visit "/objects/#{druid}"

    expect(page).to have_css('h1', text: original_title)

    # Tabs
    expect(page).to have_css('.nav-link.active', text: 'Details')
    expect(page).to have_css('.nav-link', text: 'Workflows')
    expect(page).to have_css('.nav-link', text: 'Versions')
    expect(page).to have_css('.nav-link.disabled', text: 'Events')
    expect(page).to have_css('.nav-link', text: 'Cocina Model')

    # Overview table
    expect(page).to have_css('table[id="overview-table"] caption', text: 'Overview')
    expect(page).to have_table_value('overview-table', 'Object type', 'Admin policy')
    within(find_table_value_cell('overview-table', 'Admin policy')) do
      expect(page).to have_link('My APO', href: "/objects/#{apo_druid}")
      expect(page).to have_link('All objects with this APO',
                                href: '/search?admin_policy_titles%5B%5D=My+APO&page=1')
    end

    # Description table
    expect(page).to have_css('table[id="description-table"] caption', text: 'Description')
    expect(page).to have_table_value('description-table', 'Title', original_title)

    # Cocina model tab
    click_button 'Cocina Model'
    # andypf-json-viewer uses a shadow DOM, so can't check for content within it.
    expect(page).to have_css("andypf-json-viewer[data*='#{druid}']")
    expect(page).to have_css("andypf-json-viewer[data*='#{original_title}']")

    allow(Sdr::Repository).to receive(:find_solr).and_return(build_solr_doc(title: updated_title))
    allow(Sdr::Repository).to receive(:find).and_return(build_cocina_object(title: updated_title))

    expect(page).to have_css('h1', text: updated_title)
    expect(page).to have_css("andypf-json-viewer[data*='#{updated_title}']")

    click_button 'Details'
    expect(page).to have_table_value('description-table', 'Title', updated_title)
  end
end
