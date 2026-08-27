# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pin and unpin a tag' do
  let(:druid) { 'druid:bb123cd4567' }
  let(:apo_druid) { 'druid:cc123cd4578' }
  let(:title) { 'My agreement title' }

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, milestones: milestones_client,
                                                   user_version: user_version_client, lock: 'lock1')
  end
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: [], status: version_status) }
  let(:version_status) do
    instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, accessioning?: true, closed?: true)
  end
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: []) }
  let(:milestones_client) { instance_double(Dor::Services::Client::Milestones, list: []) }

  let(:solr_doc) do
    {
      Search::Fields::ID => druid,
      Search::Fields::OBJECT_TYPES => ['agreement'],
      Search::Fields::CONTENT_TYPES => ['agreement'],
      Search::Fields::TITLE => title,
      Search::Fields::APO_DRUID => [apo_druid],
      Search::Fields::APO_TITLE => ['My APO'],
      Search::Fields::COLLECTION_DRUIDS => [],
      Search::Fields::COLLECTION_TITLES => [],
      Search::Fields::OTHER_TAGS => ['Project : Foo']
    }
  end

  let(:cocina_object) do
    build(:agreement_with_metadata, id: druid, admin_policy_id: apo_druid, title:)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
    allow(Sdr::Repository).to receive_messages(find_solr: solr_doc, find: cocina_object)

    sign_in(create(:user))
  end

  it 'pins from the object show page and unpins from the dashboard' do
    visit "/objects/#{druid}"

    within('.card', text: 'Tags') do
      expect(page).to have_link('Project : Foo', href: search_path(projects: ['Foo']))
      expect(page).to have_button('Pin')

      click_button 'Pin'
    end

    within('.card', text: 'Tags') do
      expect(page).to have_button('Unpin')
      expect(page).to have_no_button('Pin')
    end
    expect(page).to have_toast('Pin added')

    visit root_path

    expect(page).to have_link('Project : Foo', href: search_path(projects: ['Foo']))
    expect(page).to have_button('Unpin')

    click_button 'Unpin'

    expect(page).to have_no_link('Project : Foo')
    expect(page).to have_text('No tags have been pinned.')
    expect(page).to have_toast('Pin removed')
  end
end
