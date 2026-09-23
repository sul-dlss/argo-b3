# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::CollectionsComponent, type: :component do
  let(:component) { described_class.new(form:, options:) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:item, item_form, vc_test_view_context, {}) }
  let(:item_form) { ItemForm.new(collection_druids: %w[druid:bc123df4567 druid:xz987wv6543]) }
  let(:options) { [['Art History Slides', 'druid:bc123df4567'], %w[xz987wv6543 druid:xz987wv6543]] }

  it 'renders the collections select with the selected collections' do
    render_inline(component)

    expect(page).to have_css('fieldset legend', text: 'Collections')
    expect(page).to have_select('Collections', multiple: true, visible: :all,
                                               selected: ['Art History Slides', 'xz987wv6543'])
    expect(page).to have_css('select[data-controller="tom-select"][data-tom-select-url-value="/collection_options"]',
                             visible: :all)
    form_params = JSON.parse(page.find('select', visible: :all)['data-tom-select-form-params-value'])
    expect(form_params).to eq('apo_druid' => 'item[apo_druid]', 'limit_by_apo' => 'item[limit_collection_by_apo]')
  end

  it 'renders the limit by APO checkbox without a hidden field' do
    render_inline(component)

    expect(page).to have_unchecked_field('Only view collections in selected APO')
    expect(page).to have_no_field('item[limit_collection_by_apo]', type: 'hidden', visible: :all)
  end
end
