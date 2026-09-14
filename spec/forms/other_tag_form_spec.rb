# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OtherTagForm do
  subject(:other_tag_form) { described_class.new(tag:) }

  let(:error_message) { 'must be a series of 2 or more strings delimited with space-padded colons' }

  describe 'tag' do
    context 'when two strings delimited with a space-padded colon' do
      let(:tag) { 'Registered By : mjgiarlo' }

      it 'is valid' do
        expect(other_tag_form).to be_valid
      end
    end

    context 'when more than two strings delimited with space-padded colons' do
      let(:tag) { 'Registered By : mjgiarlo : now' }

      it 'is valid' do
        expect(other_tag_form).to be_valid
      end
    end

    context 'when nil' do
      let(:tag) { nil }

      it 'is valid' do
        expect(other_tag_form).to be_valid
      end
    end

    context 'when blank' do
      let(:tag) { '' }

      it 'is normalized to nil and is valid' do
        expect(other_tag_form).to be_valid
        expect(other_tag_form.tag).to be_nil
      end
    end

    context 'when whitespace only' do
      let(:tag) { '   ' }

      it 'is normalized to nil and is valid' do
        expect(other_tag_form).to be_valid
        expect(other_tag_form.tag).to be_nil
      end
    end

    context 'when surrounded by whitespace' do
      let(:tag) { '  Registered By : mjgiarlo  ' }

      it 'is normalized by stripping whitespace and is valid' do
        expect(other_tag_form).to be_valid
        expect(other_tag_form.tag).to eq('Registered By : mjgiarlo')
      end
    end

    context 'when a single string with no delimiter' do
      let(:tag) { 'Registered By' }

      it 'is not valid' do
        expect(other_tag_form).not_to be_valid
        expect(other_tag_form.errors[:tag]).to include(error_message)
      end
    end

    context 'when the colon is not space-padded' do
      let(:tag) { 'Registered By:mjgiarlo' }

      it 'is not valid' do
        expect(other_tag_form).not_to be_valid
        expect(other_tag_form.errors[:tag]).to include(error_message)
      end
    end

    context 'when a string is missing on one side of the delimiter' do
      let(:tag) { 'Registered By : ' }

      it 'is not valid' do
        expect(other_tag_form).not_to be_valid
        expect(other_tag_form.errors[:tag]).to include(error_message)
      end
    end
  end
end
