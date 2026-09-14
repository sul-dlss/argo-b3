# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Elements::Forms::HasManyRowComponent, type: :component do
  before do
    stub_const('WidgetForm', widget_form_class)
    stub_const('WidgetComponent', widget_component_class)
  end

  let(:widget_form_class) do
    Class.new(Blanks::Base) do
      attribute :name, :string
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

  let(:widget) { WidgetForm.new(name: 'A widget') }
  # Mirrors the builder that fields_for yields for a has_many row: the index is carried by
  # the object name and by child_index, which is what FormBuilder#index reads.
  let(:form) do
    ActionView::Helpers::FormBuilder.new('widgets_form[widgets_attributes][0]', widget, vc_test_view_context,
                                         { child_index: 0 })
  end
  let(:component) { described_class.new(form:, form_component: WidgetComponent) }

  it 'renders a row marked for the has-many Stimulus controller' do
    render_inline(component)

    expect(page).to have_css('.form-instance[data-has-many-target="row"][data-index="0"]')
  end

  it 'renders the fields of the nested form component' do
    render_inline(component)

    expect(page).to have_field('widgets_form[widgets_attributes][0][name]', with: 'A widget')
  end

  it 'renders a Remove button' do
    render_inline(component)

    expect(page).to have_css('button[data-action="has-many#remove"]')
    expect(page).to have_button('Remove')
  end

  context 'when the nested form builder is for a client-side template row' do
    let(:form) do
      ActionView::Helpers::FormBuilder.new('widgets_form[widgets_attributes][NEW_RECORD]', widget,
                                           vc_test_view_context, { child_index: 'NEW_RECORD' })
    end

    it 'indexes the row with the placeholder index' do
      render_inline(component)

      expect(page).to have_css('.form-instance[data-index="NEW_RECORD"]')
    end
  end
end
