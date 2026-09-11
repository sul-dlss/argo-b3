# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrevalidationConcern do
  # ItemRegistrationForm is used as a representative form that includes the concern.
  subject(:form) { ItemRegistrationForm.new(source_id: 'sul:1234', title: 'A title') }

  describe '#valid?' do
    context 'when the form is prevalidated' do
      before { form.prevalidated! }

      it 'raises an AlreadyValidatedError' do
        expect { form.valid? }.to raise_error(described_class::AlreadyValidatedError, /ItemRegistrationForm/)
      end

      it 'raises an AlreadyValidatedError for invalid? as well' do
        expect { form.invalid? }.to raise_error(described_class::AlreadyValidatedError)
      end

      it 'does not discard the errors' do
        form.errors.add(:title, 'is not valid')

        expect { form.valid? }.to raise_error(described_class::AlreadyValidatedError)
        expect(form.errors[:title]).to eq(['is not valid'])
      end
    end

    context 'when the form is not prevalidated' do
      it 'validates the form' do
        expect(form).to be_valid
      end
    end
  end
end
