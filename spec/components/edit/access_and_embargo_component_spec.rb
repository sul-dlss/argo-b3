# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::AccessAndEmbargoComponent, type: :component do
  let(:component) { described_class.new(form:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:item, new_item_form, vc_test_view_context, {}) }
  let(:new_item_form) { NewItemForm.new }

  it 'renders the embargo toggle' do
    render_inline(component)

    expect(page).to have_field('Without embargo', type: 'radio')
    expect(page).to have_field('With embargo', type: 'radio')
  end

  it 'renders the embargo release date field' do
    render_inline(component)

    expect(page).to have_field('When will this embargo end?', type: 'date', name: 'item[embargo_release_date]')
  end

  context 'with an embargo release date' do
    let(:new_item_form) { NewItemForm.new(with_embargo: true, embargo_release_date: '2027-03-15') }

    it 'renders the release date as a date' do
      render_inline(component)

      expect(page).to have_field('When will this embargo end?', type: 'date', with: '2027-03-15')
    end
  end

  it 'renders the access rights for each embargo state' do
    render_inline(component)

    expect(page).to have_select('View access', name: 'item[access_view]', count: 2)
    expect(page).to have_select('View access', name: 'item[embargo_view]', count: 1)
  end

  it 'renders the object access as during the embargo and the embargo access as once the embargo ends' do
    render_inline(component)

    expect(page).to have_css('fieldset:has(> legend:contains("Access settings during embargo")) ' \
                             'select[name="item[access_view]"]')
    expect(page).to have_css('fieldset:has(> legend:contains("Access settings once embargo ends")) ' \
                             'select[name="item[embargo_view]"]')
  end

  it 'renders the targets that the toggle Stimulus controller expects' do
    render_inline(component)

    expect(page).to have_css('[data-controller="toggle"]')
    expect(page).to have_css('input[data-toggle-target="radio"][data-toggle-section="without-embargo"]')
    expect(page).to have_css('input[data-toggle-target="radio"][data-toggle-section="with-embargo"]')
    expect(page).to have_css('[data-toggle-target="section"][data-toggle-section="without-embargo"]')
    expect(page).to have_css('[data-toggle-target="section"][data-toggle-section="with-embargo"]')
  end

  context 'when showing APO defaults' do
    let(:component) { described_class.new(form:, apo_defaults: true) }

    it 'shows APO defaults for the access without embargo and once the embargo ends, but not during the embargo' do
      render_inline(component)

      expect(page).to have_css('fieldset:has(> legend:contains("Access settings without embargo")) ' \
                               '[data-apo-defaults-group="without_embargo"] select[name="item[access_view]"]')
      expect(page).to have_css('fieldset:has(> legend:contains("Access settings once embargo ends")) ' \
                               '[data-apo-defaults-group="embargo_ends"] select[name="item[embargo_view]"]')
      expect(page).to have_no_css('fieldset:has(> legend:contains("Access settings during embargo")) ' \
                                  '[data-apo-defaults-group]')
    end
  end

  context 'when not showing APO defaults' do
    it 'does not render the apo-defaults targets' do
      render_inline(component)

      expect(page).to have_no_css('[data-apo-defaults-target]', visible: :all)
    end
  end
end
