# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultipleItemsPolicy, type: :policy do
  subject(:policy) { described_class.new(form_validation_action, user:) }

  let(:form_validation_action) do
    FormValidationAction.create!(user: owner, form: ItemsRegistrationForm.new, status: 'queued')
  end
  let(:owner) { create(:user) }

  describe '#show?' do
    subject { policy.apply(:show?) }

    context 'when the form validation action belongs to the user' do
      let(:user) { owner }

      it { is_expected.to be true }
    end

    context 'when the form validation action belongs to another user' do
      let(:user) { create(:user) }

      it { is_expected.to be false }
    end
  end
end
