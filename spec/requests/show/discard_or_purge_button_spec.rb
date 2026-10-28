# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show object purge / discard draft button' do
  include_context 'with show page object client'

  let(:druid) { 'druid:bc123df4567' }
  let(:version) { 1 }
  let(:user) { create(:user, :reader) }
  let(:permission_trait) { :edit }
  let(:rendered_page) { Capybara.string(response.body) }

  before do
    allow(Sdr::Repository).to receive_messages(
      lock: object_lock,
      find: build(:dro_with_metadata, id: druid, version:),
      find_solr: { Search::Fields::ID => druid, Search::Fields::TITLE => 'My object',
                   Search::Fields::OBJECT_TYPES => ['item'] }
    )
    allow(Sdr::PurgeService).to receive(:purgeable?).and_return(true)
    allow(Sdr::DiscardDraftService).to receive(:discardable?).and_return(true)
    create(:permission, permission_trait, workgroup: user.groups.first, target_druid: druid)
    sign_in(user)
  end

  context 'when a first version can be purged' do
    it 'renders an enabled Purge object button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css("form[action='/objects/#{druid}/purge'] input[name='_method'][value='delete']",
                                        visible: :all)
      expect(rendered_page).to have_css('button:not(.disabled)', exact_text: 'Purge object')
      expect(rendered_page).to have_no_button('Discard draft')
    end
  end

  context 'when a first version cannot be purged' do
    before do
      allow(Sdr::PurgeService).to receive(:purgeable?).and_return(false)
    end

    it 'renders a disabled Purge object button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_button('Purge object', class: 'disabled')
    end
  end

  context 'when a later version can be discarded' do
    let(:version) { 2 }

    before do
      allow(Sdr::PurgeService).to receive(:purgeable?).and_return(false)
    end

    it 'renders an enabled Discard draft button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_css(
        "form[action='/objects/#{druid}/discard_draft'] input[name='_method'][value='delete']", visible: :all
      )
      expect(rendered_page).to have_css('button:not(.disabled)', exact_text: 'Discard draft')
      expect(rendered_page).to have_no_button('Purge object')
    end
  end

  context 'when a later version cannot be discarded' do
    let(:version) { 2 }

    before do
      allow(Sdr::PurgeService).to receive(:purgeable?).and_return(false)
      allow(Sdr::DiscardDraftService).to receive(:discardable?).and_return(false)
    end

    it 'renders a disabled Discard draft button' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_button('Discard draft', class: 'disabled')
    end
  end

  context 'when the user cannot update the object' do
    let(:permission_trait) { :read_restricted }

    it 'renders a disabled button without checking whether the object can be purged or discarded' do
      get "/objects/#{druid}"

      expect(rendered_page).to have_button('Purge object', class: 'disabled')
      expect(Sdr::PurgeService).not_to have_received(:purgeable?)
      expect(Sdr::DiscardDraftService).not_to have_received(:discardable?)
    end
  end
end
