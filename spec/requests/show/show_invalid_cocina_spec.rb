# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show object with invalid cocina' do
  let(:druid) { 'druid:bc123df4567' }
  let(:apo_druid) { 'druid:hv992ry2431' }
  let(:rendered_page) { Capybara.string(response.body) }
  let(:solr_response) do
    {
      'response' => {
        'numFound' => 1, 'start' => 0,
        'docs' => [{ Search::Fields::ID => druid, Search::Fields::TITLE => 'My invalid object',
                     Search::Fields::OBJECT_TYPES => ['item'], Search::Fields::APO_DRUID => [apo_druid] }]
      }
    }
  end

  before do
    allow(Sdr::Repository).to receive(:lock).with(druid:).and_return('lock1')
    allow(Sdr::Repository).to receive(:find).and_raise(Sdr::Repository::InvalidCocinaError,
                                                       'Invalid cocina (unevaluated property bogus)')
    allow(Sdr::Repository).to receive(:find_solr)
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
    sign_in(user)
  end

  context 'when the user can read the object' do
    let(:user) { create(:user, :reader) }

    it 'renders heading from the solr doc, replaces full show page with a warning, suppresses the read only badge' do
      get "/objects/#{druid}"

      expect(response).to have_http_status(:ok)
      expect(rendered_page).to have_title('My invalid object | Argo B3')
      expect(rendered_page).to have_css('.object-type-badge', text: 'Item')
      expect(rendered_page).to have_css('h1', exact_text: 'My invalid object')
      expect(rendered_page).to have_button('Pin')
      expect(rendered_page).to have_no_css('.read-only-badge')
      expect(rendered_page).to have_css('.alert-warning', text: 'This object is currently not available, likely ' \
                                                                'because it is part of an ongoing cocina migration.')
      expect(rendered_page).to have_no_css('[role="tablist"]')
      expect(rendered_page).to have_no_link('Manage tags')

      expect(Search::SolrService).to have_received(:post)
        .with(request: hash_including(fq: ["id:(\"#{druid}\")"]))
      expect(Sdr::Repository).not_to have_received(:find_solr)
    end
  end

  context 'when the user can edit the object' do
    let(:user) { create(:user) }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: apo_druid) }

    it 'still renders no edit controls' do
      get "/objects/#{druid}"

      expect(response).to have_http_status(:ok)
      expect(rendered_page).to have_no_link('Manage tags')
    end
  end

  context 'when the user cannot read the object' do
    let(:user) { create(:user) }

    it 'refuses access' do
      get "/objects/#{druid}"

      expect(response).to redirect_to(root_path)
      expect(flash[:danger]).to be_present
    end
  end

  context 'when the object is not in Solr' do
    let(:user) { create(:user, :reader) }
    let(:solr_response) { { 'response' => { 'numFound' => 0, 'start' => 0, 'docs' => [] } } }

    it 'renders a 404' do
      get "/objects/#{druid}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
