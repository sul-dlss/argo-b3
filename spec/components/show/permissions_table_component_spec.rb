# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::PermissionsTableComponent, type: :component do
  let(:component) { described_class.new(permission_types_by_workgroup:) }

  context 'with permissions' do
    let(:permission_types_by_workgroup) { { 'sdr:developer' => 'edit', 'sdr:smpl-staff' => 'read_restricted' } }

    before { render_inline(component) }

    it 'renders the workgroups with their permission labels' do
      expect(page).to have_css('h2', text: 'Permissions')
      expect(page).to have_css('#permissions-table th', text: 'Workgroup')
      expect(page).to have_css('#permissions-table th', text: 'Permission')
      rows = page.all('#permissions-table tbody tr').map { |row| row.all('td').map(&:text) }
      expect(rows).to eq([%w[sdr:developer Edit], %w[sdr:smpl-staff Read]])
    end
  end

  context 'without permissions' do
    let(:permission_types_by_workgroup) { {} }

    before { render_inline(component) }

    it 'renders the empty message' do
      expect(page).to have_css('h2', text: 'Permissions')
      expect(page).to have_css('p', text: 'No permissions.')
      expect(page).to have_no_css('#permissions-table tbody tr')
    end
  end
end
