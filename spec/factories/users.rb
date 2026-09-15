# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "sunetid#{n}@stanford.edu" }
    sequence(:name) { |n| "A#{n}. User" }
    groups { ['sdr:argo-access'] }

    trait :admin do
      groups { ['sdr:argo-access', AuthenticationHelpers::ADMIN_GROUP] }
    end

    trait :reader do
      after(:create) do |user|
        Permission.find_or_create_by!(workgroup: user.groups.first, permission_type: :read_unrestricted)
      end
    end

    trait :developer do
      groups { ['sdr:developer'] }
    end
  end
end
