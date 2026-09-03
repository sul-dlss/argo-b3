# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show agreement' do
  let(:druid) { 'druid:bb123cd4567' }
  let(:apo_druid) { 'druid:cc123cd4578' }
  let(:title) { 'My agreement title' }

  # Versions and workflows are tested in show_dro_spec, so returning minimal/empty values here.
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
      Search::Fields::COLLECTION_TITLES => []
    }
  end

  let(:cocina_object) do
    build(:agreement_with_metadata, id: druid, admin_policy_id: apo_druid, title:)
  end

  before do
    create(:permission, :read_unrestricted, workgroup: 'sdr:argo-access')

    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
    allow(Sdr::Repository).to receive_messages(find_solr: solr_doc, find: cocina_object)

    sign_in(create(:user))
  end

  it 'displays the agreement' do
    visit "/objects/#{druid}"

    expect(page).to have_css('h1', text: title)
    expect(page).to have_css('.object-show.object-type-agreement .object-type-badge', text: 'AGREEMENT')

    # No pin
    expect(page).to have_no_css('.bi-pin')
    expect(page).to have_no_css('.bi-pin-fill')
  end
end
