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

    trait :with_export do
      transient do
        export_content { 'Export content' }
      end
      after(:create) do |bulk_action, evaluator|
        raise 'No export filename configured for this action type' if bulk_action.export_filename.nil?

        File.write(bulk_action.export_filepath, evaluator.export_content)
      end
    end
  end
end
