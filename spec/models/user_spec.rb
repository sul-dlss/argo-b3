# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  describe '#sunetid' do
    subject(:user) { described_class.new(email_address: 'a.user@stanford.edu') }

    it 'returns the SUNetID by removing the email suffix' do
      expect(user.sunetid).to eq('a.user')
    end
  end
end
