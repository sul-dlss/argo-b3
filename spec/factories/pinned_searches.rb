# frozen_string_literal: true

FactoryBot.define do
  factory :pinned_search do
    search_form_attributes { ResultsSearchForm.new(query: 'test').attributes }
    user
  end
end
