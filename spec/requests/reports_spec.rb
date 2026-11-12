# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reports' do
  before do
    sign_in(create(:user, :reader))
  end

  describe 'show' do
    it 'renders one h1 and a level-2 heading for each field section' do
      get report_path

      expect(response).to have_http_status(:ok)
      page = Capybara.string(response.body)
      expect(page).to have_css('h1', count: 1)
      expect(page).to have_css('h1', text: 'Custom report')
      expect(page.all('h2').map { |heading| heading.text.strip })
        .to eq(['Frequently used', 'Citation', 'History', 'Identifiers', 'Content'])
    end

    it 'renders the source of items chooser' do
      get report_path

      page = Capybara.string(response.body)
      expect(page).to have_css('fieldset legend', exact_text: 'Select source of items for report', normalize_ws: true)
      expect(page).to have_field('From last search', type: 'radio', disabled: true)
      expect(page).to have_field('From druid list', type: 'radio', checked: true)
      expect(page).to have_field('Enter druid list', type: 'textarea')
    end
  end

  describe 'preview' do
    context 'when the last search cookie has an attribute the search form no longer has' do
      let(:csv_string) { +"druid_bare_ssi\nbc123df4567\n" }

      before do
        allow(Search::SolrService).to receive(:post).and_return(csv_string)
        cookies[:last_search] = Rails.application
                                     .message_verifier(Rails.application.config.action_dispatch.signed_cookie_salt)
                                     .generate({ form: { 'query' => 'cats', 'removed_attribute' => 'x' },
                                                 total_results: 1 })
      end

      it 'generates the report from the remaining attributes' do
        post preview_report_path,
             params: { report: { source: 'results', fields: ['druid_bare_ssi'] }, commit: 'Preview' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('bc123df4567')
        expect(Search::SolrService).to have_received(:post) do |args|
          expect(args[:request].with_indifferent_access['q']).to eq('cats')
        end
      end
    end
  end
end
