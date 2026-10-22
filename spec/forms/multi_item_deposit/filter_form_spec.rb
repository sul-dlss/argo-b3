# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::FilterForm do
  describe '#statuses_filter' do
    it 'returns nil when no statuses are provided' do
      expect(described_class.new.statuses_filter).to be_nil
    end

    it 'returns no statuses when only the blank value of the select is provided' do
      expect(described_class.new(statuses: ['']).statuses_filter).to eq([])
    end

    it 'returns the selected statuses when some statuses are provided' do
      expect(described_class.new(statuses: ['', 'submitted']).statuses_filter).to eq(['submitted'])
    end
  end

  describe '#submitted_since' do
    it 'returns the start of the submitted date range' do
      freeze_time do
        expect(described_class.new(submitted_date: 'last_7_days').submitted_since).to eq(7.days.ago)
      end
    end

    it 'returns nil when the submitted date is unknown' do
      expect(described_class.new(submitted_date: 'last_century').submitted_since).to be_nil
    end
  end

  describe '#filters' do
    it 'returns the filters for the Multi-Item Deposits' do
      form = described_class.new(statuses: ['', 'submitted'])

      expect(form.filters).to eq(statuses: ['submitted'], submitted_since: nil, user_ids: nil)
    end
  end

  describe '#user_ids_filter' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    before { create(:multi_item_deposit_action, user: other_user) }

    it 'returns the current user when an admin provides no user ids' do
      expect(described_class.new(user:, admin: true).user_ids_filter).to eq([user.id.to_s])
    end

    it 'returns no user ids when an admin provides only the blank value of the select' do
      expect(described_class.new(user_ids: [''], user:, admin: true).user_ids_filter).to eq([])
    end

    it 'returns nil when an admin selects all users' do
      form = described_class.new(user_ids: ['', user.id.to_s, other_user.id.to_s], user:, admin: true)

      expect(form.user_ids_filter).to be_nil
    end

    it 'returns nil when not an admin, whatever user ids are provided' do
      expect(described_class.new(user_ids: [other_user.id.to_s], user:).user_ids_filter).to be_nil
    end
  end

  describe '#user_options' do
    let(:user) { create(:user, email_address: 'mmouse@stanford.edu') }

    before do
      create(:multi_item_deposit_action, user: create(:user, email_address: 'dduck@stanford.edu'))
      create(:multi_item_deposit_action, user: create(:user, email_address: 'bbunny@stanford.edu'))
      create(:bulk_action, user: create(:user, email_address: 'nodeposits@stanford.edu'))
    end

    it 'returns the current user followed by the other users with Multi-Item Deposits, sorted by sunetid' do
      expect(described_class.new(user:, admin: true).user_options.map(&:first)).to eq(%w[mmouse bbunny dduck])
    end
  end

  describe '#status_options' do
    it 'returns label and display status pairs' do
      expect(described_class.new.status_options).to eq([%w[Submitted submitted],
                                                        ['Initiating deposit', 'initiating_deposit'],
                                                        ['Discovering files', 'discovering'],
                                                        ['Checking files', 'structuring'],
                                                        ['Not submitted', 'not_submitted']])
    end
  end

  describe '#active_filter_params' do
    it 'returns no params when no filter limits the Multi-Item Deposits' do
      expect(described_class.new.active_filter_params).to eq({})
    end

    it 'returns the params of the filters that limit the Multi-Item Deposits' do
      form = described_class.new(statuses: ['', 'submitted'], submitted_date: 'last_year')

      expect(form.active_filter_params).to eq(statuses: ['', 'submitted'], submitted_date: 'last_year')
    end

    context 'when an admin' do
      let(:user) { create(:user) }

      it 'returns no user ids param when only the current user is selected' do
        form = described_class.new(user_ids: ['', user.id.to_s], user:, admin: true)

        expect(form.active_filter_params).to eq({})
      end

      it 'returns the user ids param when no users are selected' do
        form = described_class.new(user_ids: [''], user:, admin: true)

        expect(form.active_filter_params).to eq(user_ids: [''])
      end
    end
  end

  describe '#submitted_date_options' do
    it 'returns label and key pairs' do
      expect(described_class.new.submitted_date_options).to eq([['View all', 'all'], ['Last 7 days', 'last_7_days'],
                                                                ['Last month', 'last_month'],
                                                                ['Last 3 months', 'last_3_months'],
                                                                ['Last 6 months', 'last_6_months'],
                                                                ['Last year', 'last_year']])
    end
  end
end
