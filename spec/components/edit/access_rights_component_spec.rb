# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::AccessRightsComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(nil, manage_rights_form, vc_test_view_context, {}) }

  context 'when the form has the default access rights' do
    let(:manage_rights_form) { BulkActions::ManageRightsForm.new }

    it 'renders the view access select' do
      render_inline(component)

      expect(page).to have_select('View access', selected: 'World',
                                                 options: ['World', 'Dark', 'Citation Only', 'Stanford',
                                                           'Location Based'])
    end

    it 'renders the download access select' do
      render_inline(component)

      expect(page).to have_select('Download access', selected: 'World',
                                                     options: ['World', 'Stanford', 'Location Based', 'None'])
    end

    # The form defaults location to nil, so no option is selected server-side.
    it 'renders the location select' do
      render_inline(component)

      expect(page).to have_select('Location', options: ['Special collections', 'Music', 'ARS', 'Art',
                                                        'Hoover Institute', 'Media and Microtext'])
    end
  end

  context 'when the form has location-based access rights' do
    let(:manage_rights_form) do
      BulkActions::ManageRightsForm.new(view: 'location-based', download: 'none', location: 'spec')
    end

    it 'renders the selected access rights' do
      render_inline(component)

      expect(page).to have_select('View access', selected: 'Location Based')
      expect(page).to have_select('Download access', selected: 'None')
      expect(page).to have_select('Location', selected: 'Special collections')
    end
  end

  context 'when a fieldname prefix is provided' do
    let(:component) { described_class.new(form:, fieldname_prefix: 'embargo_') }
    let(:form) { ActionView::Helpers::FormBuilder.new(:item, item_form, vc_test_view_context, {}) }
    let(:item_form) { ItemForm.new(embargo_view: 'stanford', embargo_download: 'none', embargo_location: 'music') }

    it 'prefixes the field names' do
      render_inline(component)

      expect(page).to have_select('View access', name: 'item[embargo_view]', selected: 'Stanford')
      expect(page).to have_select('Download access', name: 'item[embargo_download]', selected: 'None')
      expect(page).to have_select('Location', name: 'item[embargo_location]', selected: 'Music')
    end
  end

  context 'when wiring the access rights Stimulus controller' do
    let(:manage_rights_form) { BulkActions::ManageRightsForm.new }

    it 'renders the targets that the controller expects' do
      render_inline(component)

      expect(page).to have_css('[data-controller="access-rights"]')
      expect(page).to have_css('select[data-access-rights-target="view"][data-action="access-rights#toggle"]')
      expect(page).to have_css('select[data-access-rights-target="download"][data-action="access-rights#toggle"]')
      expect(page).to have_css('select[data-access-rights-target="location"]')
    end
  end
end
