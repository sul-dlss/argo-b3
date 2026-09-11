# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::Forms::HasManyComponent, type: :component do
  before do
    stub_const('WidgetForm', widget_form_class)
    stub_const('WidgetsForm', widgets_form_class)
    stub_const('WidgetComponent', widget_component_class)
  end

  let(:widget_form_class) do
    Class.new(Blanks::Base) do
      attribute :name, :string
    end
  end

  let(:widgets_form_class) do
    Class.new(Blanks::Base) do
      has_many :widgets, class_name: 'WidgetForm'
    end
  end

  let(:widget_component_class) do
    Class.new(ApplicationComponent) do
      def initialize(form:)
        @form = form
        super()
      end

      attr_reader :form

      def call
        form.text_field :name
      end
    end
  end

  let(:parent_form) { WidgetsForm.new }
  let(:form) { ActionView::Helpers::FormBuilder.new(:widgets_form, parent_form, vc_test_view_context, {}) }
  let(:component) { described_class.new(form:, field_name: :widgets, form_component: WidgetComponent) }

  it 'wires up the has-many Stimulus controller' do
    render_inline(component)

    expect(page).to have_css('[data-controller="has-many"]')
  end

  it 'renders an Add button and, for each row, a Remove button' do
    render_inline(component)

    expect(page).to have_button('Add')
    expect(page).to have_button('Remove')
  end

  it 'seeds the client-side template row with the NEW_RECORD placeholder index' do
    # Capybara/Nokogiri does not expose <template> content through page/have_css matchers,
    # so this asserts on the raw rendered markup instead.
    html = component.render_in(vc_test_view_context)

    expect(html).to include('data-index="NEW_RECORD"')
    expect(html).to include('widgets_attributes][NEW_RECORD][name]')
  end

  context 'when the collection is empty' do
    it 'renders a single blank row' do
      render_inline(component)

      expect(page).to have_css('.form-instance', count: 1)
      expect(page).to have_field('widgets_form[widgets_attributes][0][name]')
    end
  end

  context 'when the collection already has widgets' do
    before { parent_form.widgets.new(name: 'Existing widget') }

    it 'renders one row per existing widget, without adding a blank row' do
      render_inline(component)

      expect(page).to have_css('.form-instance', count: 1)
      expect(page).to have_field('widgets_form[widgets_attributes][0][name]', with: 'Existing widget')
    end
  end
end
