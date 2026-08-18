# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PinnedObject do
  let(:user) { create(:user) }

  describe 'validations' do
    context 'with a user and a valid druid' do
      let(:pinned_object) { create(:pinned_object, druid: 'druid:bc123df4567') }

      it 'is valid' do
        expect(pinned_object).to be_valid
      end
    end

    context 'without a druid' do
      subject(:pinned_object) { described_class.new(user:, druid: nil) }

      it 'is invalid' do
        expect(pinned_object).not_to be_valid
        expect(pinned_object.errors[:druid]).to include("can't be blank")
      end
    end

    context 'when the druid is not correctly formatted' do
      subject(:pinned_object) { described_class.new(user:, druid: 'not-a-druid') }

      it 'is invalid' do
        expect(pinned_object).not_to be_valid
        expect(pinned_object.errors[:druid]).to include('is not a valid druid')
      end
    end
  end
end
