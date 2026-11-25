# frozen_string_literal: true

FactoryBot.define do
  factory :tracked_deposit do
    druid { 'druid:bc123df4567' }
    version { 2 }
    user
  end
end
