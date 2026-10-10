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
    visit "/objects/#{druid}"

    expect(page).to have_css('h1', text: title)
    expect(page).to have_css('.object-show.object-type-agreement .object-type-badge', text: 'AGREEMENT')

    # No pin
    expect(page).to have_no_css('.bi-pin')
    expect(page).to have_no_css('.bi-pin-fill')
  end
end
