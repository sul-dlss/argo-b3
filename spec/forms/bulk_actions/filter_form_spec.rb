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

      expect(form.filters).to eq(action_types: nil, statuses: ['completed'], submitted_since: nil)
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
