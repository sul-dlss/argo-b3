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
        # Defaults to the first export configured for the action type.
        export_key { nil }
      end
      after(:create) do |bulk_action, evaluator|
        raise 'No exports configured for this action type' if bulk_action.exports.empty?

        export_key = evaluator.export_key || bulk_action.exports.first.key
        File.write(bulk_action.export_filepath(export_key), evaluator.export_content)
      end
    end
  end
end
