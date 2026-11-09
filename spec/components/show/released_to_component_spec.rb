# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ReleasedToComponent, type: :component do
  subject(:component) { described_class.new(object_released_presenter:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:object_type) { 'item' }
  let(:access_rights) { ['world'] }
  let(:solr_doc) { SolrDocPresenter.new(solr_doc: build(:solr_item, druid:, object_type:, access_rights:)) }
  let(:user) { create(:user) }
  let(:release_tags) do
    [instance_double(Dor::Services::Client::ReleaseTag, to: 'Searchworks', release: true),
     instance_double(Dor::Services::Client::ReleaseTag, to: 'PURL sitemap', release: true)]
  end
  let(:object_released_presenter) do
    ObjectReleasedPresenter.new(solr_doc:, release_tags:,
                                version_service: version_service_double(version: 2, open?: false, accessioning?: false))
  end

  before { allow(Current).to receive(:user).and_return(user) }

  context 'when there are release target links' do
    it 'renders a link for each release target' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Released to')
      expect(page).to have_link('Searchworks (opens in new tab)', href: %r{\Ahttps://searchworks})
      expect(page.find_link('Searchworks')[:target]).to eq('_blank')
      expect(page).to have_css('a i.bi-box-arrow-up-right[aria-hidden="true"]', count: 2)
      expect(page).to have_link('Search engines', href: %r{/bc123df4567\z})
    end
  end

  context 'when there are no release target links' do
    let(:release_tags) { [] }

    it 'renders the heading and no list' do
      render_inline(component)

      expect(page).to have_css('h2', text: 'Not released')
      expect(page).to have_no_css('ul')
    end
  end

  context 'when the user can release an item' do
    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders the manage release button' do
      render_inline(component)

      expect(page).to have_link('Manage release', href: "/items/#{druid}/releases/new")
    end
  end

  context 'when the user can release a virtual object' do
    let(:object_type) { 'virtual object' }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'renders the manage release button' do
      render_inline(component)

      expect(page).to have_link('Manage release', href: "/items/#{druid}/releases/new")
    end
  end

  context 'when the item is dark' do
    let(:access_rights) { ['dark'] }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'does not render the manage release button' do
      render_inline(component)

      expect(page).to have_no_link('Manage release')
    end
  end

  context 'when the user cannot release an item' do
    it 'does not render the manage release button' do
      render_inline(component)

      expect(page).to have_no_link('Manage release')
    end
  end

  context 'when the object is a collection' do
    let(:object_type) { 'collection' }

    before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

    it 'does not render the manage release button' do
      render_inline(component)

      expect(page).to have_no_link('Manage release')
    end
  end
end
