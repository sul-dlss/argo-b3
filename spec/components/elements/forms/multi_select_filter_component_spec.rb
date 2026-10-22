# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::Forms::MultiSelectFilterComponent, type: :component do
  let(:filter_form) { EventsFilterForm.new(event_types: ['registration']) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:events_filter_form, filter_form, vc_test_view_context, {}) }
  let(:options) { [%w[Registration registration], %w[Update update]] }

  context 'with the default select all' do
    it 'renders a labeled multiple select with checkbox Tom Select' do
      render_inline(described_class.new(form:, field_name: :event_types, options:, label_text: 'Event types'))

      expect(page).to have_css('label[for="events_filter_form_event_types"]', text: 'Event types')
      expect(page).to have_css('select[multiple][name="events_filter_form[event_types][]"]' \
                               '[data-controller="checkbox-tom-select"]' \
                               '[data-checkbox-tom-select-select-all-value="true"]')
      expect(page).to have_css('option[value="registration"][selected]', text: 'Registration')
      expect(page).to have_css('option[value="update"]:not([selected])', text: 'Update')
      expect(page).to have_field('events_filter_form[event_types][]', type: :hidden, with: '')
    end
  end

  context 'without select all' do
    it 'renders the select without Select all / Select none' do
      render_inline(described_class.new(form:, field_name: :event_types, options:, label_text: 'Event types',
                                        select_all: false))

      expect(page).to have_css('select[data-checkbox-tom-select-select-all-value="false"]')
    end
  end

  context 'with container classes' do
    it 'renders the container with the classes' do
      render_inline(described_class.new(form:, field_name: :event_types, options:, label_text: 'Event types',
                                        container_classes: 'col-md-4'))

      expect(page).to have_css('div.col-md-4 > select#events_filter_form_event_types')
    end
  end
end
