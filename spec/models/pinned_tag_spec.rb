# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PinnedTag do
  let(:user) { create(:user) }

  describe 'validations' do
    context 'with a user and a tag' do
      let(:pinned_tag) { create(:pinned_tag) }

      it 'is valid' do
        expect(pinned_tag).to be_valid
      end
    end

    context 'without a tag' do
      subject(:pinned_tag) { described_class.new(user:, tag: nil) }

      it 'is invalid' do
        expect(pinned_tag).not_to be_valid
        expect(pinned_tag.errors[:tag]).to include("can't be blank")
      end
    end
  end
end
