# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "sunetid#{n}@stanford.edu" }
    sequence(:name) { |n| "A#{n}. User" }
  end
end
