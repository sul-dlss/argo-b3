# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show releases' do
  let(:druid) { 'druid:bc123df4567' }
  let(:token) do
    Rails.application.message_verifier(:argo).generate(druid, purpose: 'show', expires_at: 1.week.from_now.end_of_day)
  end
  let(:object_client) { instance_double(Dor::Services::Client::Object, release_tags: release_tags_client) }
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: release_tags) }
  let(:release_tags) do
    [
      Dor::Services::Client::ReleaseTag.new(to: 'Searchworks', what: 'collection', release: true, who: 'estanfor',
                                            date: '2021-07-16T22:58:07Z'),
      Dor::Services::Client::ReleaseTag.new(to: 'Earthworks', what: 'self', release: false, who: 'jdoe',
                                            date: '2022-01-05T17:00:00Z')
    ]
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in(create(:user))
  end

  describe 'GET /objects/:druid/releases' do
    it 'raises when token verification fails' do
      get '/objects/not-a-valid-token/releases'

      expect(response).to have_http_status(:forbidden)
      expect(Dor::Services::Client).not_to have_received(:object)
    end

    it 'lists the release tag history' do
      get "/objects/#{token}/releases"

      expect(response).to have_http_status(:ok)
      expect(Dor::Services::Client).to have_received(:object).with(druid)
      expect(release_tags_client).to have_received(:list).with(public: false)

      page = Capybara.string(response.body)
      expect(page).to have_css('h2', text: 'Releases')
      within(page.find('table#releases-table')) do
        expect(page).to have_css('th', text: 'Release')
        expect(page).to have_css('th', text: 'What')
        expect(page).to have_css('th', text: 'To')
        expect(page).to have_css('th', text: 'User')
        expect(page).to have_css('th', text: 'Date')
      end

      cells = page.find(:xpath, "//table[@id='releases-table']//tr[./th[normalize-space()='true']]").all('td')
      expect(cells.map(&:text)).to eq(['collection', 'Searchworks', 'estanfor', '2021-07-16 15:58:07 PT'])

      cells = page.find(:xpath, "//table[@id='releases-table']//tr[./th[normalize-space()='false']]").all('td')
      expect(cells.map(&:text)).to eq(['self', 'Earthworks', 'jdoe', '2022-01-05 09:00:00 PT'])
    end

    context 'when there are no release tags' do
      let(:release_tags) { [] }

      it 'shows no releases' do
        get "/objects/#{token}/releases"

        expect(response.body).to include('No releases yet.')
      end
    end
  end
end
