# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentFile do
  describe 'deposit validation context' do
    let(:deposit_ready_attributes) do
      {
        external_identifier: 'https://cocina.sul.stanford.edu/file/abc'
      }
    end

    it 'is valid when required attributes are present' do
      expect(build(:content_file, **deposit_ready_attributes)).to be_valid(:deposit)
    end

    it 'is invalid without external_identifier' do
      content_file = build(:content_file, **deposit_ready_attributes, external_identifier: nil)

      expect(content_file).not_to be_valid(:deposit)
      expect(content_file.errors[:external_identifier]).to include("can't be blank")
    end
  end
end
