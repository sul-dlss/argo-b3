# frozen_string_literal: true

FactoryBot.define do
  factory :content_file do
    content_file_set
    position { 1 }
    file_location { 'attached' }
    label { 'Image 1' }
    filepath { 'image1.tif' }
    basename { 'image1' }
    extname { '.tif' }
    view { 'world' }
    download { 'world' }
    publish { true }
    preserve { true }
    shelve { true }
  end
end
