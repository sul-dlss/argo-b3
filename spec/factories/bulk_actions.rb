# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_action do
    action_type { 'reindex' }
    user

    trait :with_log do
      transient do
        log_content { 'Log content' }
      end
      after(:create) do |bulk_action, evaluator|
        File.write(bulk_action.log_filepath, evaluator.log_content)
      end
    end

    trait :with_report do
      transient do
        report_content { 'Report content' }
      end
      after(:create) do |bulk_action, evaluator|
        raise 'No report filename configured for this action type' if bulk_action.report_filename.nil?

        File.write(bulk_action.report_filepath, evaluator.report_content)
      end
    end
  end
end
