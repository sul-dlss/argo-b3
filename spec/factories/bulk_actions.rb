# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_action do
    action_type { 'reindex' }
    user
    log_filepath { 'tmp/log.txt' }
  end
end
