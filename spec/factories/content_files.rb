# frozen_string_literal: true

FactoryBot.define do
  factory :content_file do
    content_file_set
    content_file_binary { association :content_file_binary, content: content_file_set.content }
    position { 1 }
    label { 'Image 1' }
    mime_type { 'image/tiff' }
    view { 'world' }
    download { 'world' }
    publish { true }
    preserve { true }
    shelve { true }
  end
end
