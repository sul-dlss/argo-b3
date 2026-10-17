# frozen_string_literal: true

FactoryBot.define do
  factory :content do
    druid { generate(:unique_druid) }
    lock { 'druid-version-1' }

    # The immutable column defaults to true; mutable Content is what edits, discovery, and staging work on.
    trait :mutable do
      immutable { false }
    end
  end
end
