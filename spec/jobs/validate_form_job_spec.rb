# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ValidateFormJob do
  subject(:job) { described_class.new }

  let(:user) { create(:user) }
  let(:form_validation_action) { FormValidationAction.create!(user:, form:, status: 'queued') }

  describe '#perform' do
    context 'when the form is valid' do
      let(:form) { SearchForm.new(query: 'test') }

      it 'marks the form validation action valid' do
        job.perform(form_validation_action:)

        expect(form_validation_action.reload).to be_status_valid
        expect(form_validation_action.error_data).to be_nil
      end
    end

    context 'when the form is invalid' do
      let(:form) { ItemRegistrationForm.new(source_id: 'sul:1234') }

      it 'marks the form validation action invalid and records the errors' do
        job.perform(form_validation_action:)

        expect(form_validation_action.reload).to be_status_invalid
        expect(form_validation_action.error_data['errors'].pluck('attribute')).to eq(['title'])
      end

      it 'returns a form with the errors applied' do
        job.perform(form_validation_action:)

        expect(form_validation_action.reload.form.errors[:title])
          .to eq(['title is required if a FOLIO Instance HRID is not provided'])
      end
    end

    context 'when validating mutates the form' do
      let(:form) do
        ItemsRegistrationForm.new(
          item_registrations_attributes: [{ title: '', source_id: '' }, { title: 'A title', source_id: 'sul:1234' }]
        )
      end

      it 'rewrites the form payload with the form as validated' do
        job.perform(form_validation_action:)

        expect(form_validation_action.reload.form.item_registrations.map(&:title)).to eq(['A title'])
      end
    end

    context 'when validating is underway' do
      let(:form) { SearchForm.new(query: 'test') }

      it 'has marked the form validation action started' do
        status_while_validating = nil
        allow(form_validation_action).to receive(:form) do
          form.tap { status_while_validating = form_validation_action.reload.status }
        end

        job.perform(form_validation_action:)

        expect(status_while_validating).to eq('started')
      end
    end

    context 'when validating the form raises' do
      let(:form) { SearchForm.new(query: 'test') }
      let(:error) { StandardError.new('oops') }

      before do
        allow(form_validation_action).to receive(:form).and_raise(error)
        allow(Honeybadger).to receive(:notify)
      end

      it 'marks the form validation action failed and notifies Honeybadger' do
        job.perform(form_validation_action:)

        expect(form_validation_action.reload).to be_status_failed
        expect(Honeybadger).to have_received(:notify)
          .with(error, context: { form_validation_action_id: form_validation_action.id, user: user.sunetid })
      end
    end
  end
end
