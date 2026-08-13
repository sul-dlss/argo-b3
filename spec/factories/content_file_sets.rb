# frozen_string_literal: true

FactoryBot.define do
  factory :content_file_set do
    content
    position { 1 }
    file_set_type { 'file' }
    label { 'Object 1' }
  end
end
