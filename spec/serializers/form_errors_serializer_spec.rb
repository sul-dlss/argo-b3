# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FormErrorsSerializer do
  describe '.serialize' do
    # These examples use stubbed forms rather than application forms so that they do not have to be
    # updated as attributes and associations are added to the application forms.
    let(:widget_form_class) do
      Class.new(ApplicationForm) do
        attribute :name, :string
      end
    end
    let(:form) { WidgetForm.new }

    before { stub_const('WidgetForm', widget_form_class) }

    context 'when the errors were added with a message' do
      before { form.errors.add(:name, 'name is required') }

      it 'serializes the message as a string type' do
        expect(described_class.serialize(form)).to eq(
          'errors' => [
            { 'attribute' => 'name',
              'type' => 'name is required',
              'type_class' => 'String',
              'options' => {} }
          ]
        )
      end
    end

    context 'when the errors were added with a symbol type and options' do
      before { form.errors.add(:name, :too_short, count: 5) }

      it 'serializes the type as a symbol type along with the options' do
        expect(described_class.serialize(form)).to eq(
          'errors' => [
            { 'attribute' => 'name',
              'type' => 'too_short',
              'type_class' => 'Symbol',
              'options' => { 'count' => 5 } }
          ]
        )
      end
    end

    context 'when the form has has_many nested forms' do
      let(:widgets_form_class) do
        Class.new(ApplicationForm) do
          attribute :label, :string

          has_many :widgets
        end
      end
      let(:form) { WidgetsForm.new(widgets_attributes: [{ name: nil }, { name: 'A name' }]) }

      before do
        stub_const('WidgetsForm', widgets_form_class)
        form.errors.add(:'widgets[0].name', 'name is required')
        form.widgets.first.errors.add(:name, 'name is required')
      end

      it 'serializes the errors of the nested forms alongside the errors of the form' do
        expect(described_class.serialize(form)).to eq(
          'errors' => [
            { 'attribute' => 'widgets[0].name',
              'type' => 'name is required',
              'type_class' => 'String',
              'options' => {} }
          ],
          'widgets_attributes' => [
            { 'errors' => [
              { 'attribute' => 'name',
                'type' => 'name is required',
                'type_class' => 'String',
                'options' => {} }
            ] },
            { 'errors' => [] }
          ]
        )
      end
    end

    context 'when the form has a has_one nested form' do
      let(:widgets_form_class) do
        Class.new(ApplicationForm) do
          attribute :label, :string

          has_one :widget
        end
      end
      let(:form) { WidgetsForm.new.tap(&:build_widget) }

      before do
        stub_const('WidgetsForm', widgets_form_class)
        form.errors.add(:label, :blank)
        form.widget.errors.add(:name, 'name is required')
      end

      it 'serializes the errors of the nested form alongside the errors of the form' do
        expect(described_class.serialize(form)).to eq(
          'errors' => [
            { 'attribute' => 'label',
              'type' => 'blank',
              'type_class' => 'Symbol',
              'options' => {} }
          ],
          'widget_attributes' => {
            'errors' => [
              { 'attribute' => 'name',
                'type' => 'name is required',
                'type_class' => 'String',
                'options' => {} }
            ]
          }
        )
      end
    end

    context 'when the error options contain arrays and hashes of JSON primitives' do
      before { form.errors.add(:name, :inclusion, in: %w[first second], counts: { first: 1 }) }

      it 'serializes the options' do
        expect(described_class.serialize(form)).to eq(
          'errors' => [
            { 'attribute' => 'name',
              'type' => 'inclusion',
              'type_class' => 'Symbol',
              'options' => { 'in' => %w[first second], 'counts' => { first: 1 } } }
          ]
        )
      end
    end

    context 'when an error option will not round trip through jsonb' do
      before { form.errors.add(:name, :invalid, value: Date.new(2026, 9, 11)) }

      it 'raises an UnserializableOptionError' do
        expect { described_class.serialize(form) }
          .to raise_error(described_class::UnserializableOptionError, /Date option value on name/)
      end
    end

    context 'when an error option is an array containing a value that will not round trip through jsonb' do
      before { form.errors.add(:name, :invalid, values: [Date.new(2026, 9, 11)]) }

      it 'raises an UnserializableOptionError' do
        expect { described_class.serialize(form) }
          .to raise_error(described_class::UnserializableOptionError, /Array option values on name/)
      end
    end

    context 'when an error option is a hash containing a value that will not round trip through jsonb' do
      before { form.errors.add(:name, :invalid, values: { from: Date.new(2026, 9, 11) }) }

      it 'raises an UnserializableOptionError' do
        expect { described_class.serialize(form) }
          .to raise_error(described_class::UnserializableOptionError, /Hash option values on name/)
      end
    end
  end

  describe '.deserialize' do
    context 'when the form has no nested forms' do
      subject(:deserialized_form) { described_class.deserialize(form: ItemRegistrationForm.new, error_data:) }

      let(:error_data) do
        {
          'errors' => [
            { 'attribute' => 'title', 'type' => 'too_short', 'type_class' => 'Symbol',
              'options' => { 'count' => 5 } },
            { 'attribute' => 'source_id', 'type' => 'is not a valid source ID', 'type_class' => 'String',
              'options' => {} }
          ]
        }
      end

      it 'adds the errors to the form' do
        expect(deserialized_form.errors.map { |error| [error.attribute, error.type, error.options] }).to eq(
          [[:title, :too_short, { count: 5 }], [:source_id, 'is not a valid source ID', {}]]
        )
      end

      it 'renders the message for a symbol type from the options' do
        expect(deserialized_form.errors.first.message).to eq('is too short (minimum is 5 characters)')
      end

      it 'marks the form as prevalidated' do
        expect(deserialized_form).to be_prevalidated
      end
    end

    context 'when the form does not include PrevalidationConcern' do
      it 'raises an ArgumentError' do
        expect { described_class.deserialize(form: SearchForm.new, error_data: { 'errors' => [] }) }
          .to raise_error(ArgumentError, /SearchForm must include PrevalidationConcern/)
      end
    end

    context 'when the form has nested forms' do
      subject(:deserialized_form) { described_class.deserialize(form:, error_data:) }

      let(:form) do
        ItemsRegistrationForm.new(
          item_registrations_attributes: [{ source_id: 'sul:1234' }, { source_id: 'sul:5678', title: 'A title' }]
        )
      end
      let(:error_data) do
        {
          'errors' => [
            { 'attribute' => 'item_registrations[0].title', 'type' => 'title is required',
              'type_class' => 'String', 'options' => {} }
          ],
          'item_registrations_attributes' => [
            { 'errors' => [
              { 'attribute' => 'title', 'type' => 'title is required', 'type_class' => 'String', 'options' => {} }
            ] },
            { 'errors' => [] }
          ]
        }
      end

      it 'adds the errors to the form' do
        expect(deserialized_form.errors[:'item_registrations[0].title']).to eq(['title is required'])
      end

      it 'adds the errors to the nested forms' do
        expect(deserialized_form.item_registrations.first.errors[:title]).to eq(['title is required'])
        expect(deserialized_form.item_registrations.to_a.second.errors).to be_empty
      end

      it 'marks the nested forms as prevalidated' do
        expect(deserialized_form.item_registrations).to all(be_prevalidated)
      end
    end

    context 'when the form has a has_one nested form' do
      subject(:deserialized_form) { described_class.deserialize(form:, error_data:) }

      let(:widget_form_class) do
        Class.new(ApplicationForm) do
          include PrevalidationConcern

          attribute :name, :string
        end
      end
      let(:widgets_form_class) do
        Class.new(ApplicationForm) do
          include PrevalidationConcern

          has_one :widget
        end
      end
      let(:form) { WidgetsForm.new.tap(&:build_widget) }
      let(:error_data) do
        {
          'errors' => [],
          'widget_attributes' => {
            'errors' => [
              { 'attribute' => 'name', 'type' => 'name is required', 'type_class' => 'String', 'options' => {} }
            ]
          }
        }
      end

      before do
        stub_const('WidgetForm', widget_form_class)
        stub_const('WidgetsForm', widgets_form_class)
      end

      it 'adds the errors to the nested form' do
        expect(deserialized_form.widget.errors[:name]).to eq(['name is required'])
      end

      it 'marks the nested form as prevalidated' do
        expect(deserialized_form.widget).to be_prevalidated
      end
    end
  end

  describe 'round trip' do
    let(:form) do
      ItemsRegistrationForm.new(
        apo_druid: 'druid:bc123df4567',
        content_type: Cocina::Models::ObjectType.book,
        access_view: 'world',
        access_download: 'world',
        item_registrations_attributes: [{ source_id: 'sul:1234' }]
      )
    end
    let(:deserialized_form) do
      described_class.deserialize(form: ItemsRegistrationForm.new(form.attributes),
                                  error_data: described_class.serialize(form).as_json)
    end

    before do
      allow(Sdr::Repository).to receive(:source_id_exists?).and_return(false)
      form.valid?
    end

    it 'preserves the errors of the form and its nested forms' do
      expect(deserialized_form.errors.messages).to eq(form.errors.messages)
      expect(deserialized_form.item_registrations.first.errors.messages)
        .to eq(form.item_registrations.first.errors.messages)
    end

    context 'when an other tag is malformed' do
      let(:form) do
        ItemsRegistrationForm.new(
          apo_druid: 'druid:bc123df4567',
          content_type: Cocina::Models::ObjectType.book,
          access_view: 'world',
          access_download: 'world',
          item_registrations_attributes: [{ source_id: 'sul:1234', title: 'A title' }],
          other_tags_attributes: [{ tag: 'Registered By' }]
        )
      end

      it 'preserves the error message of the tag' do
        expect(deserialized_form.other_tags.first.errors[:tag])
          .to eq(['must be a series of 2 or more strings delimited with space-padded colons'])
      end
    end
  end
end
