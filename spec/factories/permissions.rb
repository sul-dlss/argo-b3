# frozen_string_literal: true

FactoryBot.define do
  factory :permission do
    workgroup { 'sdr:administrator-role' }
    permission_type { 'admin' }

    trait :admin do
      permission_type { 'admin' }
    end

    trait :read_unrestricted do
      permission_type { 'read_unrestricted' }
    end

    trait :read_restricted do
      permission_type { 'read_restricted' }
      target_druid { generate(:unique_druid) }
    end

    trait :edit do
      permission_type { 'edit' }
      target_druid { generate(:unique_druid) }
    end
  end
end
