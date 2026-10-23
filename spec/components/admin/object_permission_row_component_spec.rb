# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ObjectPermissionRowComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:permission) do
    build_stubbed(:permission, :read_restricted, workgroup: 'sdr:curators', target_druid: 'druid:bc123df4567')
  end
  let(:component) { described_class.new(permission:) }
  let(:table) { Capybara.string("<table><tbody>#{component.render_in(vc_test_view_context)}</tbody></table>") }

  it 'renders the workgroup, Read label, and object-scoped delete button' do
    expect(table.all('td').first(2).map { |cell| cell.text.strip }).to eq(['sdr:curators', 'Read'])
    expect(table).to have_button('Delete Read permission for sdr:curators')
    expect(table).to have_css("form[action='#{admin_object_permission_path('druid:bc123df4567', permission)}']")
    expect(table).to have_css("input[name='_method'][value='delete']", visible: :all)
  end

  context 'when the permission is Edit' do
    let(:permission) { build_stubbed(:permission, :edit, workgroup: 'sdr:curators', target_druid: 'druid:bc123df4567') }

    it 'renders the Edit label' do
      expect(table.all('td').first(2).map { |cell| cell.text.strip }).to eq(['sdr:curators', 'Edit'])
      expect(table).to have_button('Delete Edit permission for sdr:curators')
    end
  end
end
