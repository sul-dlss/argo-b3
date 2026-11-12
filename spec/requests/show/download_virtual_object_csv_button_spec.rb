# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show object Download virtual object CSV button' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:rendered_page) { Capybara.string(response.body) }

  before do
    allow(Sdr::Repository).to receive_messages(
      lock: object_lock,
      find: cocina_object,
      find_solr: { Search::Fields::ID => druid, Search::Fields::TITLE => 'My object',
                   Search::Fields::OBJECT_TYPES => [object_type],
                   # Rendered for APOs.
                   Search::Fields::AGREEMENT_DRUID => 'druid:dd123fg4567',
                   Search::Fields::AGREEMENT_TITLE => 'My agreement' }
    )
    sign_in(create(:user, :reader))
  end

  context 'when the object is a virtual object' do
    let(:object_type) { 'virtual object' }

    it 'renders the button after Download description' do
      get "/objects/#{druid}"

      actions = rendered_page.find(:xpath, "//h2[normalize-space()='Actions']/..")
      labels = actions.all('a, button').map { |element| element.text.strip }
      expect(labels.each_cons(2)).to include(['Download description', 'Download virtual object CSV'])
      form = actions.find('form', text: 'Download virtual object CSV')
      token = form[:action][%r{\A/objects/([^/]+)/virtual_object_csv\z}, 1]
      expect(Rails.application.message_verifier(:argo).verify(token, purpose: 'show')).to eq druid
    end
  end

  %w[item collection APO agreement].each do |type|
    context "when the object is a #{type}" do
      let(:object_type) { type }

      it 'does not render the button' do
        get "/objects/#{druid}"

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_no_text('Download virtual object CSV')
      end
    end
  end
end
