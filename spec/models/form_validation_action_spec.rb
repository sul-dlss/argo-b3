# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FormValidationAction do
  let(:user) { create(:user) }
  let(:form) { SearchForm.new(query: 'test', object_types: %w[collection item]) }

  describe 'validations' do
    subject(:form_validation_action) { described_class.new(user:) }

    it 'requires a form payload' do
      expect(form_validation_action).not_to be_valid
      expect(form_validation_action.errors[:form_payload]).to include("can't be blank")
    end
  end

  describe '#form' do
    subject(:form_validation_action) { described_class.new(user:, form:) }

    it 'round-trips the form for an unsaved record' do
      expect(form_validation_action.form).to be_a(SearchForm)
      expect(form_validation_action.form.attributes).to eq(form.attributes)
    end

    it 'round-trips the form for a persisted record' do
      form_validation_action.save!

      reloaded_form = form_validation_action.reload.form
      expect(reloaded_form).to be_a(SearchForm)
      expect(reloaded_form.attributes).to eq(form.attributes)
    end

    context 'when the form has a nested association' do
      let(:form) do
        ItemsRegistrationForm.new(
          item_registrations_attributes: [{ title: 'A title', source_id: 'sul:1234' }]
        )
      end

      it 'round-trips the nested attributes' do
        form_validation_action.save!

        reloaded_form = form_validation_action.reload.form
        expect(reloaded_form).to be_a(ItemsRegistrationForm)
        expect(reloaded_form.attributes).to eq(form.attributes)
        expect(reloaded_form.item_registrations.map(&:title)).to eq(['A title'])
      end
    end

    context 'when there is error data' do
      subject(:form_validation_action) do
        described_class.new(user:, form:, error_data: {
                              'errors' => [
                                { 'attribute' => 'title', 'type' => 'is not valid',
                                  'type_class' => 'String', 'options' => {} }
                              ]
                            })
      end

      # The form must include PrevalidationConcern for its errors to be deserialized.
      let(:form) { ItemRegistrationForm.new(source_id: 'sul:1234') }

      it 'applies the errors to the form and marks it prevalidated' do
        expect(form_validation_action.form.errors[:title]).to eq(['is not valid'])
        expect(form_validation_action.form).to be_prevalidated
      end
    end
  end

  describe '#mark_valid!' do
    subject(:form_validation_action) do
      described_class.create!(user:, form: SearchForm.new, status: 'started', error_data: { 'errors' => [] })
    end

    it 'records the status, the validated form, and no error data' do
      form_validation_action.mark_valid!(form)

      expect(form_validation_action.reload).to be_status_valid
      expect(form_validation_action.error_data).to be_nil
      expect(form_validation_action.form.attributes).to eq(form.attributes)
    end
  end

  describe '#mark_invalid!' do
    subject(:form_validation_action) do
      described_class.create!(user:, form: SearchForm.new, status: 'started')
    end

    let(:invalid_form) { ItemRegistrationForm.new(source_id: 'sul:1234') }

    before { invalid_form.valid? }

    it 'records the status, the validated form, and the error data' do
      form_validation_action.mark_invalid!(invalid_form)

      expect(form_validation_action.reload).to be_status_invalid
      expect(form_validation_action.error_data).to eq(FormErrorsSerializer.serialize(invalid_form).as_json)
      expect(form_validation_action.form.attributes).to eq(invalid_form.attributes)
    end
  end

  describe '#form=' do
    subject(:form_validation_action) { described_class.new(user:) }

    context 'when the form cannot be serialized' do
      it 'raises an ArgumentError' do
        expect { form_validation_action.form = Object.new }.to raise_error(ArgumentError)
      end
    end
  end
end
