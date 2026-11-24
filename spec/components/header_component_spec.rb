# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HeaderComponent, type: :component do
  let(:component) { described_class.new }

  let(:user) { build_stubbed(:user, name: 'Test User') }

  before do
    allow(Current).to receive_messages(user:, impersonating?: false)
  end

  it 'renders the header' do
    render_inline(component)

    expect(page).to have_css('header .masthead .h1', exact_text: 'Argo B3')
    expect(page).to have_link(href: '/', exact_text: 'Argo B3')
    expect(page).to have_link(href: 'mailto:argo-feedback@lists.stanford.edu', text: 'Feedback')
    expect(page).to have_css('.nav-item', text: 'Logged in as Test User')
    expect(page).to have_css('.nav-item:contains("Logged in as Test User") + .nav-item a[href="/notifications"]',
                             exact_text: 'Notifications')
    expect(page).to have_link('Workflow status', href: '/workflow_grid')
  end

  describe 'bulk actions menu' do
    let(:menu) { page.find('li.mega-menu') }

    it 'renders links to the bulk actions pages' do
      with_request_url '/bulk_actions/new' do
        render_inline(component)
      end

      expect(menu).to have_button('Bulk actions')
      expect(menu).to have_css('[role="heading"]', exact_text: 'Bulk action pages')
      expect(menu).to have_link('Recent bulk actions', href: '/bulk_actions')
      expect(menu).to have_css('a[aria-current="page"][href="/bulk_actions/new"]', exact_text: 'Bulk actions menu')
    end

    it 'renders a section for each bulk action section with links to its bulk actions' do
      render_inline(component)

      expect(menu.all('[role="heading"]').map(&:text))
        .to eq(['Bulk action pages', 'Perform actions', 'Register and deposit', 'Tags and reporting',
                'Modify objects', 'Manage structural metadata', 'Manage rights and administrative metadata',
                'Manage descriptive metadata'])
      expect(menu).to have_link('Manage release', href: '/bulk_actions/manage_release/new')
      expect(menu).to have_link('Add workflow', href: '/bulk_actions/add_workflow/new')
    end

    context 'when the user is not an admin' do
      it 'does not render bulk actions limited to admins' do
        render_inline(component)

        expect(menu).to have_no_css('[role="heading"]', text: 'Manage permissions')
        expect(menu).to have_no_link('Import read unrestricted workgroups')
      end
    end

    context 'when the user is an admin' do
      let(:user) { build_stubbed(:user, :admin, name: 'Admin User') }

      it 'renders bulk actions limited to admins' do
        render_inline(component)

        expect(menu).to have_css('[role="heading"]', exact_text: 'Manage permissions')
        expect(menu).to have_link('Import read unrestricted workgroups',
                                  href: '/bulk_actions/import_read_unrestricted_workgroups/new')
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

      it 'renders an enabled link for collection registration' do
        render_inline(component)

        expect(page).to have_link('Collection', href: '/collections/new')
        expect(page).to have_no_css('a.dropdown-item.disabled', text: 'Collection')
      end

      it 'renders an enabled link for multiple item registration' do
        render_inline(component)

        expect(page).to have_link('Register multiple items', href: '/multiple_items/new')
        expect(page).to have_no_css('a.dropdown-item.disabled', exact_text: 'Register multiple items')
      end

      it 'renders an enabled link for multi-item deposit' do
        render_inline(component)

        expect(page).to have_css("a.dropdown-item[href='/multi_item_deposit_actions'][data-turbo-method='post']",
                                 exact_text: 'Deposit multiple items')
        expect(page).to have_no_css('a.dropdown-item.disabled', exact_text: 'Deposit multiple items')
      end
    end

    context 'when the user belongs to a workgroup with edit permission for the ur APO' do
      let(:user) { build_stubbed(:user, name: 'Test User', groups: [workgroup]) }
      let(:workgroup) { 'sdr:test-workgroup' }

      before do
        create(:permission, :edit, workgroup:, target_druid: Settings.ur_apo_druid)
      end

      it 'renders an enabled link for agreement registration' do
        render_inline(component)

        expect(page).to have_link('Agreement', href: '/agreements/new')
        expect(page).to have_no_css('a.dropdown-item.disabled', text: 'Agreement')
      end
    end

    context 'when the user is an admin' do
      let(:user) { build_stubbed(:user, :admin, name: 'Admin User') }

      it 'renders an enabled link for APO registration' do
        render_inline(component)

        expect(page).to have_link('APO', href: '/apos/new')
        expect(page).to have_no_css('a.dropdown-item.disabled', text: 'APO')
      end
    end

    context 'when the user does not belong to a workgroup with edit permission' do
      it 'renders a disabled link for item registration' do
        render_inline(component)

        expect(page).to have_css('a.dropdown-item.disabled', text: 'Item')
      end

      it 'renders a disabled link for multiple item registration' do
        render_inline(component)

        expect(page).to have_css('a.dropdown-item.disabled', exact_text: 'Register multiple items')
      end

      it 'renders a disabled link for multi-item deposit' do
        render_inline(component)

        expect(page).to have_css('a.dropdown-item.disabled', exact_text: 'Deposit multiple items')
      end
    end
  end

  describe 'reports dropdown' do
    it 'renders a link to the druid report' do
      render_inline(component)

      expect(page).to have_link('Druid report', href: '/report')
    end

    it 'renders a disabled link for the aggregate report' do
      render_inline(component)

      expect(page).to have_css('a.dropdown-item.disabled', text: 'Aggregate report')
    end
  end

  describe 'admin links' do
    context 'when the user is an admin' do
      let(:user) { build_stubbed(:user, :admin, name: 'Admin User') }

      it 'renders admin links including impersonate' do
        render_inline(component)

        expect(page).to have_link('Manage permissions', href: '/admin/workgroup_permissions')
        expect(page).to have_link('Impersonate', href: '/admin/impersonate')
      end
    end

    context 'when the user is impersonating' do
      before do
        allow(Current).to receive(:impersonating?).and_return(true)
      end

      it 'renders impersonate and stop impersonating links' do
        render_inline(component)

        expect(page).to have_link('Impersonate', href: '/admin/impersonate')
        expect(page).to have_link('Stop impersonating', href: '/admin/impersonate')
      end
    end

    context 'when the user is not an admin and not impersonating' do
      it 'does not render the admin links' do
        render_inline(component)

        expect(page).to have_no_link('Manage permissions')
        expect(page).to have_no_link('Impersonate')
      end
    end
  end
end
