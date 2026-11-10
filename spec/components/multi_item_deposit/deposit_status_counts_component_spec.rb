# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::DepositStatusCountsComponent, type: :component do
  let(:component) { described_class.new(object_status_presenters:) }
  let(:object_status_presenters) do
    { 'druid:bc123df4567' => version_service_double(closed?: true),
      'druid:cd234fg5678' => version_service_double,
      'druid:df345gh6789' => version_service_double(closed?: true),
      'druid:fg456hj7890' => version_service_double(accessioning?: true) }
      .map do |druid, version_service|
        ObjectStatusPresenter.new(solr_doc: SolrDocPresenter.new(solr_doc: build(:solr_item, druid:)),
                                  version_service:, content: nil)
      end
  end

  it 'renders the total and the count of each status in a status region' do
    render_inline(component)

    expect(page).to have_css('[role="status"]',
                             exact_text: 'Total: 4; Depositing: 1; Registered: 1; Deposited: 2')
  end
end
