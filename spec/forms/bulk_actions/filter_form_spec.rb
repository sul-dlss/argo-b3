# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::FilterForm do
  describe '#action_types_filter' do
    it 'returns nil when no action types are provided' do
      expect(described_class.new.action_types_filter).to be_nil
    end

    it 'returns no action types when only the blank value of the select is provided' do
      expect(described_class.new(action_types: ['']).action_types_filter).to eq([])
    end

    it 'returns the selected action types when some action types are provided' do
      expect(described_class.new(action_types: ['', 'REDEPOSIT', 'REINDEX']).action_types_filter)
        .to eq(%w[REDEPOSIT REINDEX])
    end
  end

  describe '#action_type_options' do
    subject(:form) { described_class.new }

    it 'returns label and action type pairs, sorted by label' do
      expect(form.action_type_options).to include(%w[Redeposit REDEPOSIT])
      expect(form.action_type_options.first).to eq(['Add workflow', 'ADD_WORKFLOW'])
    end
  end

  describe '#statuses_filter' do
    it 'returns nil when no statuses are provided' do
      expect(described_class.new.statuses_filter).to be_nil
    end

    it 'returns the selected statuses when some statuses are provided' do
      expect(described_class.new(statuses: ['', 'processing']).statuses_filter).to eq(['processing'])
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
    it 'returns the filters for the bulk actions' do
      form = described_class.new(statuses: ['', 'completed'])

      expect(form.filters).to eq(action_types: nil, statuses: ['completed'], submitted_since: nil, user_ids: nil)
    end
  end

  describe '#user_ids_filter' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    before { create(:bulk_action, user: other_user) }

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
      create(:bulk_action, user: create(:user, email_address: 'dduck@stanford.edu'))
      create(:bulk_action, user: create(:user, email_address: 'bbunny@stanford.edu'))
      create(:user, email_address: 'nobulkactions@stanford.edu')
    end

    it 'returns the current user followed by the other users with bulk actions, sorted by sunetid' do
      expect(described_class.new(user:, admin: true).user_options.map(&:first)).to eq(%w[mmouse bbunny dduck])
    end
  end

  describe '#status_options' do
    it 'returns label and display status pairs' do
      expect(described_class.new.status_options).to eq([%w[Processing processing], %w[Completed completed],
                                                        ['Completed with errors', 'completed_with_errors']])
    end
  end

  describe '#active_filter_params' do
    it 'returns no params when no filter limits the bulk actions' do
      expect(described_class.new.active_filter_params).to eq({})
    end

    it 'returns the params of the filters that limit the bulk actions' do
      form = described_class.new(statuses: ['', 'completed'], submitted_date: 'last_year')

      expect(form.active_filter_params).to eq(statuses: ['', 'completed'], submitted_date: 'last_year')
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
