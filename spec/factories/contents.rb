# frozen_string_literal: true

FactoryBot.define do
  factory :content do
    druid { generate(:unique_druid) }
    lock { 'druid-version-1' }
  end
end
