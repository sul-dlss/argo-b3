# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "sunetid#{n}@stanford.edu" }
    sequence(:name) { |n| "A#{n}. User" }
    groups { ['sdr:argo-access'] }

    trait :admin do
      groups { ['sdr:argo-access', ApplicationPolicy::ADMIN_GROUP] }
    end
  end
end
