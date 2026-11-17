# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show virtual object' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) do
    dro = build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.image)
    dro.new(structural: dro.structural.new(hasMemberOrders: [{ members: ['druid:jh330cm3013'] }]))
  end
  let(:rendered_page) { Capybara.string(response.body) }

  before do
    allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([])
    allow(Sdr::Repository).to receive_messages(
      lock: object_lock,
      find: cocina_object,
      find_solr: { Search::Fields::ID => druid, Search::Fields::TITLE => 'My virtual object',
                   Search::Fields::OBJECT_TYPES => ['virtual object'] }
    )
    sign_in(create(:user, :reader))
  end

  it 'shows the files and structure as well as the constituents' do
    get "/objects/#{druid}"

    expect(response).to have_http_status(:ok)
    tab_labels = rendered_page.all('.nav-link').map { |tab| tab.text.strip }
    expect(tab_labels.each_cons(3)).to include(%w[Constituents Files Structure])
    expect(rendered_page).to have_css('#constituents-pane turbo-frame[src*="/constituents"]')
    expect(rendered_page).to have_css('#files-pane turbo-frame[src*="/files"]')
    expect(rendered_page).to have_css('#structure-pane turbo-frame[src*="/structure"]')
    expect(rendered_page).to have_button('Download structural metadata')
  end
end
