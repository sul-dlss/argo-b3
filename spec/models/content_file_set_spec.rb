# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentFileSet do
  describe 'deposit validation context' do
    it 'is valid with an external_identifier' do
      expect(build(:content_file_set, external_identifier: 'https://cocina.sul.stanford.edu/fileSet/abc')).to(
        be_valid(:deposit)
      )
    end

    it 'is invalid without an external_identifier' do
      content_file_set = build(:content_file_set, external_identifier: nil)
      expect(content_file_set).not_to be_valid(:deposit)
      expect(content_file_set.errors[:external_identifier]).to include("can't be blank")
    end
  end
end
