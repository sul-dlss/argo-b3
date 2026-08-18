# frozen_string_literal: true

FactoryBot.define do
  factory :pinned_object do
    druid { 'druid:bc123df4567' }
    user
  end
end
