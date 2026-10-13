# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::WorkgroupPermissionRowComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(permission:, object_doc:) }
  let(:permission) { build_stubbed(:permission, :read_restricted, target_druid: 'druid:bc123df4567') }
  let(:table) do
    Capybara.string("<table><tbody>#{component.render_in(vc_test_view_context)}</tbody></table>")
  end

  context 'when the target object is available' do
    let(:object_doc) do
      SolrDocPresenter.new(solr_doc: {
                             Search::Fields::ID => 'druid:bc123df4567',
                             Search::Fields::TITLE => 'Restricted collection',
                             Search::Fields::OBJECT_TYPES => ['collection']
                           })
    end

    it 'renders the object link, permission details, and delete button in a single row' do
      expect(table).to have_css('tbody > tr', count: 1)
      expect(table).to have_link('Restricted collection', href: object_path('druid:bc123df4567'))
      expect(table.all('td').first(4).map { |cell| cell.text.strip }).to eq(
        ['Restricted collection', 'druid:bc123df4567', 'Collection', 'Read restricted']
      )
      delete_form = table.find("form[action='#{admin_permission_path(permission)}']")
      expect(delete_form).to have_css("input[name='_method'][value='delete']", visible: :all)
      expect(table).to have_button('Delete permission for druid:bc123df4567')
    end
  end

  context 'when the target object is unavailable' do
    let(:object_doc) { nil }

    it 'renders the target druid as the title without an object link' do
      expect(table.all('td').first(4).map { |cell| cell.text.strip }).to eq(
        ['druid:bc123df4567', 'druid:bc123df4567', '', 'Read restricted']
      )
      expect(table).to have_no_css('a')
    end
  end

  context 'when the permission has no target object' do
    let(:permission) { build_stubbed(:permission, :admin) }
    let(:object_doc) { nil }

    it 'identifies the permission type in the delete button' do
      expect(table).to have_button('Delete permission for Admin')
    end
  end
end
