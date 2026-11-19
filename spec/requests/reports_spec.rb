# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reports' do
  before do
    sign_in(create(:user, :reader))
  end

  describe 'show' do
    it 'renders one h1 and a level-2 heading for each field section and the preview' do
      get report_path

      expect(response).to have_http_status(:ok)
      page = Capybara.string(response.body)
      expect(page).to have_css('h1', count: 1)
      expect(page).to have_css('h1', text: 'Druid report')
      expect(page).to have_title('Druid report | Argo B3', exact: true)
      expect(page.all('h2').map { |heading| heading.text.strip })
        .to eq(['Frequently used', 'Description', 'History', 'Identifiers', 'Content', 'Preview'])
    end

    it 'renders an unticked Genre checkbox last in the Description section' do
      get report_path

      page = Capybara.string(response.body)
      section_labels = page.all(:xpath, '//div[contains(@class, "form-check")]' \
                                        '[preceding-sibling::h2[1][normalize-space()="Description"]]/label')
                           .map(&:text)
      expect(section_labels.last).to eq('Genre')
      expect(page).to have_field('Genre', type: 'checkbox', checked: false)
      expect(page).to have_css('.form-check', text: /Genre\s*For example: Dataset/)
    end

    it 'renders the source of items chooser' do
      get report_path

      page = Capybara.string(response.body)
      expect(page).to have_css('fieldset legend', exact_text: 'Select source of items for report', normalize_ws: true)
      expect(page).to have_field('From last search', type: 'radio', disabled: true)
      expect(page).to have_field('From druid list', type: 'radio', checked: true)
      expect(page).to have_field('Enter druid list', type: 'textarea')
    end

    context 'with a last search' do
      let(:search_form) { ResultsSearchForm.new(query: 'cats', object_types: ['item'], page: 5) }
      let(:total_results) { 12_345 }
      let(:druids) do
        ['druid:bc123df4567', 'druid:fg890hj1234', 'druid:jk123mn4568',
         'druid:np890qr1235', 'druid:st123vw4569', 'druid:wx890yz1236']
      end

      before do
        cookies[:last_search] = signed_last_search_cookie(search_form:, total_results:)
        allow(Search::SolrService).to receive(:post).and_return(
          'response' => { 'docs' => druids.map { |druid| { 'id' => druid } } }
        )
      end

      it 'shows six linked sample druids and an ellipsis for a larger result set' do
        get '/report'

        expect(response).to have_http_status(:ok)
        page = Capybara.string(response.body)
        expect(page).to have_field('From last search', type: 'radio', checked: true)
        expect(page).to have_css('.choice-always-shown',
                                 text: '12,345 items for: "cats" AND Object type: "item", including ' \
                                       'bc123df4567, fg890hj1234, jk123mn4568, ' \
                                       'np890qr1235, st123vw4569, wx890yz1236...')
        expect(page).to have_link('bc123df4567', href: '/objects/druid:bc123df4567')
        expect(page).to have_link('wx890yz1236', href: '/objects/druid:wx890yz1236')
        expect(Search::SolrService).to have_received(:post).with(
          request: hash_including(q: 'cats', rows: 6, fl: ['id'],
                                  fq: include('{!tag=objectType_ssimdv}objectType_ssimdv:("item")'))
        )
      end

      context 'with no results' do
        let(:total_results) { 0 }
        let(:druids) { [] }

        it 'shows the search without sample druids or an ellipsis' do
          get report_path

          page = Capybara.string(response.body)
          expect(page).to have_text('0 items for: "cats"')
          expect(page).to have_no_text('including')
          expect(page.find('.choice-always-shown')).to have_no_text('...')
        end
      end
    end
  end

  describe 'preview' do
    let(:csv_string) { +"druid_bare_ssi\nbc123df4567\n" }

    before do
      allow(Search::SolrService).to receive(:post).and_return(csv_string)
    end

    it 'limits the report to 5 rows' do
      post preview_report_path,
           params: { report: { source: 'druids', druid_list: 'bc123df4567', fields: ['druid_bare_ssi'] } }

      expect(response).to have_http_status(:ok)
      expect(Capybara.string(response.body)).to have_css('table#preview-table td', text: 'bc123df4567')
      expect(Search::SolrService).to have_received(:post).with(request: hash_including(rows: 5))
    end

    context 'when the last search cookie has an attribute the search form no longer has' do
      before do
        cookies[:last_search] = Rails.application
                                     .message_verifier(Rails.application.config.action_dispatch.signed_cookie_salt)
                                     .generate({ form: { 'query' => 'cats', 'removed_attribute' => 'x' },
                                                 total_results: 1 })
      end

      it 'generates the report from the remaining attributes' do
        post preview_report_path,
             params: { report: { source: 'results', fields: ['druid_bare_ssi'] } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('bc123df4567')
        expect(Search::SolrService).to have_received(:post) do |args|
          expect(args[:request].with_indifferent_access['q']).to eq('cats')
        end
      end
    end
  end

  describe 'download' do
    before do
      allow(Search::SolrService).to receive(:stream)
    end

    it 'does not limit the report to the preview rows' do
      post download_report_path,
           params: { report: { source: 'druids', druid_list: 'bc123df4567', fields: ['druid_bare_ssi'] } }

      expect(Search::SolrService).to have_received(:stream)
        .with(hash_including(request: hash_including(rows: 10_000_000)))
    end
  end

  describe 'Genre', :solr do
    let!(:item_doc) { create(:solr_item, genres: %w[Maps Dataset]) }
    let(:params) do
      { report: { source: 'druids', druid_list: item_doc[Search::Fields::BARE_DRUID],
                  fields: [Search::Fields::BARE_DRUID, Search::Fields::GENRES] } }
    end

    it 'previews the genres joined with ;' do
      post(preview_report_path, params:)

      page = Capybara.string(response.body)
      expect(page.all('table#preview-table th').map { |header| header.text.strip }).to eq(%w[Druid Genre])
      expect(page).to have_css('table#preview-table td', text: 'Maps;Dataset')
    end

    it 'downloads the genres joined with ;' do
      post(download_report_path, params:)

      csv = CSV.parse(response.body, headers: true)
      expect(csv.headers).to eq(%w[Druid Genre])
      expect(csv.first['Genre']).to eq('Maps;Dataset')
    end
  end
end
