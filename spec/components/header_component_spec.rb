# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HeaderComponent, type: :component do
  let(:component) { described_class.new }

  let(:user) { build_stubbed(:user, name: 'Test User') }

  before do
    allow(Current).to receive(:user).and_return(user)
  end

  it 'renders the header' do
    render_inline(component)

    expect(page).to have_css('header .masthead .h1', text: 'Argo: Build Back Better')
    expect(page).to have_link(href: '/', text: 'Argo: Build Back Better')
    expect(page).to have_link(href: 'mailto:argo-feedback@lists.stanford.edu', text: 'Feedback')
    expect(page).to have_css('.nav-item', text: 'Logged in as Test User')
    expect(page).to have_link('Workflow status', href: '/workflow_grid')
  end

  describe 'bulk actions dropdown' do
    context 'when the bulk_actions feature flag is enabled' do
      before do
        allow(Settings.feature_flags).to receive(:bulk_actions).and_return(true)
      end

      it 'renders links to the bulk actions pages' do
        render_inline(component)

        expect(page).to have_link('Recent bulk actions', href: '/bulk_actions')
        expect(page).to have_link('Bulk actions menu', href: '/bulk_actions/new')
      end
    end

    context 'when the bulk_actions feature flag is disabled' do
      before do
        allow(Settings.feature_flags).to receive(:bulk_actions).and_return(false)
      end

      it 'does not render the bulk actions dropdown' do
        render_inline(component)

        expect(page).to have_no_link('Recent bulk actions')
        expect(page).to have_no_link('Bulk actions menu')
      end
    end
  end

  describe 'register and deposit dropdown' do
    it 'renders disabled links for single object registration' do
      render_inline(component)

      expect(page).to have_css('a.dropdown-item.disabled', text: 'Item')
      expect(page).to have_css('a.dropdown-item.disabled', text: 'Collection')
      expect(page).to have_css('a.dropdown-item.disabled', text: 'APO')
      expect(page).to have_css('a.dropdown-item.disabled', text: 'Agreement')
    end

    context 'when the user belongs to a workgroup with edit permission' do
      let(:user) { build_stubbed(:user, name: 'Test User', groups: [workgroup]) }
      let(:workgroup) { 'sdr:test-workgroup' }

      before do
        create(:permission, :edit, workgroup:, target_druid: 'druid:bc123df4567')
      end

      it 'renders an enabled link for item registration' do
        render_inline(component)

        expect(page).to have_link('Item', href: '/items/new')
        expect(page).to have_no_css('a.dropdown-item.disabled', text: 'Item')
      end
    end

    context 'when the user does not belong to a workgroup with edit permission' do
      it 'renders a disabled link for item registration' do
        render_inline(component)

        expect(page).to have_css('a.dropdown-item.disabled', text: 'Item')
      end
    end

    it 'renders disabled links for multiple item registration' do
      render_inline(component)

      expect(page).to have_css('a.dropdown-item.disabled', text: 'Register multiple items')
      expect(page).to have_css('a.dropdown-item.disabled', text: 'Register multiple items for Goobi')
      expect(page).to have_css('a.dropdown-item.disabled', text: 'Deposit multiple items')
    end
  end

  describe 'reports dropdown' do
    it 'renders a link to the custom report' do
      render_inline(component)

      expect(page).to have_link('Custom report', href: '/report')
    end

    it 'renders a disabled link for the aggregate report' do
      render_inline(component)

      expect(page).to have_css('a.dropdown-item.disabled', text: 'Aggregate report')
    end
  end

  describe 'admin links' do
    context 'when the user is an admin' do
      let(:user) { build_stubbed(:user, :admin, name: 'Admin User') }

      it 'renders the disabled admin links' do
        render_inline(component)

        expect(page).to have_css('a.dropdown-item.disabled', text: 'Manage permissions')
        expect(page).to have_css('a.dropdown-item.disabled', text: 'Impersonate')
      end
    end

    context 'when the user is not an admin' do
      it 'does not render the admin links' do
        render_inline(component)

        expect(page).to have_no_link('Manage permissions')
        expect(page).to have_no_link('Impersonate')
      end
    end
  end
end
