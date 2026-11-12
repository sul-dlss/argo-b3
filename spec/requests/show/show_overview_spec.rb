# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show overview' do
  let(:druid) { 'druid:bc123cd4567' }
  let(:token) do
    Rails.application.message_verifier(:argo).generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
  end
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:solr_doc) do
    {
      Search::Fields::ID => druid,
      Search::Fields::OBJECT_TYPES => ['item'],
      Search::Fields::CONTENT_TYPES => ['image'],
      Search::Fields::APO_DRUID => ['druid:mx456pq7890'],
      Search::Fields::APO_TITLE => ['My APO'],
      Search::Fields::CONSTITUENT_OF_TITLE_DRUIDS => constituent_of
    }
  end

  before do
    sign_in(create(:user))
    allow(Sdr::Repository).to receive_messages(find: cocina_object, find_solr: solr_doc)
  end

  describe 'GET /objects/:druid/overview' do
    context 'when the object is a constituent of a virtual object' do
      let(:constituent_of) { ['Map set:druid:bb777bb7777'] }

      it 'links to the virtual object' do
        get "/objects/#{token}/overview"

        rendered_page = Capybara.string(response.body)
        table = rendered_page.find('table#virtual-objects-table')
        expect(table).to have_css('caption h2', text: 'Virtual objects')
        expect(table).to have_css('tbody tr', count: 1)
        expect(table).to have_link('Map set', href: '/objects/druid:bb777bb7777')
      end
    end

    context 'when the object is a constituent of several virtual objects' do
      let(:constituent_of) { ['Map set:druid:bb777bb7777', 'Atlas: volumes:druid:dd666dd6666'] }

      it 'lists one row per virtual object' do
        get "/objects/#{token}/overview"

        rows = Capybara.string(response.body).all('table#virtual-objects-table tbody tr')
        expect(rows.map { |row| row.text.strip }).to eq(['Map set', 'Atlas: volumes'])
        expect(rows.last).to have_link('Atlas: volumes', href: '/objects/druid:dd666dd6666')
      end
    end

    context 'when the object is not a constituent of a virtual object' do
      let(:constituent_of) { [] }

      it 'does not render the virtual objects section' do
        get "/objects/#{token}/overview"

        rendered_page = Capybara.string(response.body)
        expect(rendered_page).to have_table('identification-table')
        expect(rendered_page).to have_no_table('virtual-objects-table')
        expect(rendered_page).to have_no_text('Virtual objects')
      end
    end
  end
end
