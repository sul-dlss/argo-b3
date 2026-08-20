# frozen_string_literal: true

FactoryBot.define do
  factory :pinned_tag do
    tag { 'Registered' }
    user
  end
end
