# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ObjectPermissionRowComponent, type: :component do
  let(:component) { described_class.new(permission:) }
  let(:permission) do
    build_stubbed(:permission, :read_restricted, id: 12, workgroup: 'sdr:alpha', target_druid: 'druid:bc123df4567')
  end
  let(:table) do
    Capybara.string("<table><tbody>#{component.render_in(vc_test_view_context)}</tbody></table>")
  end

  it 'renders the workgroup, permission, and delete button in a single row' do
    expect(table).to have_css('tbody > tr#permission_12', count: 1)
    expect(table.all('td').first(2).map { |cell| cell.text.strip }).to eq(%w[sdr:alpha Read])
    delete_form = table.find("form[action='/admin/objects/druid:bc123df4567/permissions/12']")
    expect(delete_form).to have_css("input[name='_method'][value='delete']", visible: :all)
    expect(table).to have_button('Delete Read permission for sdr:alpha')
  end

  context 'when the permission is edit' do
    let(:permission) do
      build_stubbed(:permission, :edit, id: 13, workgroup: 'sdr:beta', target_druid: 'druid:bc123df4567')
    end

    it 'labels the permission as edit' do
      expect(table.all('td')[1].text.strip).to eq('Edit')
      expect(table).to have_button('Delete Edit permission for sdr:beta')
    end
  end
end
