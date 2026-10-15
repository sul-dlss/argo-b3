# frozen_string_literal: true

FactoryBot.define do
  factory :item_deposit_action do
    multi_item_deposit_action
    druid { generate(:unique_druid) }
    sequence(:path) { |n| "file#{n}" }
    sequence(:manifest_line_number, 2)
  end
end
