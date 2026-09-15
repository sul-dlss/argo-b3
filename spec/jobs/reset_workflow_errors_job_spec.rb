# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResetWorkflowErrorsJob do
  subject(:job) { described_class.new }

  let(:workflow_name) { 'accessionWF' }
  let(:user) { create(:user, :reader) }
  let(:process_name) { 'update-doi' }
  let(:search_form) { SearchForm.new(query: 'test') }

  let(:object_client) { instance_double(Dor::Services::Client::Object) }
  let(:workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow) }
  let(:process_client) { instance_double(Dor::Services::Client::Process) }

  before do
    allow(Searchers::DruidList).to receive(:call).and_return(['druid:fm262cb0015', 'druid:rt276nw8963'])
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(object_client).to receive(:workflow).and_return(workflow_client)
    allow(workflow_client).to receive(:process).and_return(process_client)
    allow(process_client).to receive(:update)
  end

  it 'resets the workflow errors for the matching items' do
    job.perform(workflow_name:, process_name:, search_form:, effective_groups: user.groups)

    expect(Searchers::DruidList).to have_received(:call).with(search_form:)
    expect(Dor::Services::Client).to have_received(:object).with('druid:fm262cb0015')
    expect(Dor::Services::Client).to have_received(:object).with('druid:rt276nw8963')
    expect(object_client).to have_received(:workflow).twice.with(workflow_name)
    expect(workflow_client).to have_received(:process).twice.with(process_name)
    expect(process_client).to have_received(:update).twice.with(status: 'waiting', current_status: 'error')
  end

  context 'with an impersonated workgroup', :solr do
    let(:user) { create(:user, :admin) }
    let(:effective_groups) { ['sdr:workflow-reader'] }
    let(:allowed_apo_druid) { 'druid:bc123df4567' }
    let!(:visible_document) do
      create(:solr_item, apo_druid: allowed_apo_druid, workflows: ['accessionWF:update-doi:error'])
    end
    let!(:hidden_document) do
      create(:solr_item, apo_druid: 'druid:fg456hj8912', workflows: ['accessionWF:update-doi:error'])
    end

    before do
      create(:permission, :read_restricted, workgroup: effective_groups.first, target_druid: allowed_apo_druid)
      allow(Searchers::DruidList).to receive(:call).and_call_original
    end

    it 'only resets readable objects using the workgroups supplied by the request' do
      job.perform(workflow_name:, process_name:, search_form:, effective_groups:)

      expect(Dor::Services::Client).to have_received(:object).with(visible_document.fetch(Search::Fields::ID)).once
      expect(Dor::Services::Client).not_to have_received(:object).with(hidden_document.fetch(Search::Fields::ID))
      expect(process_client).to have_received(:update).once.with(status: 'waiting', current_status: 'error')
    end
  end
end
