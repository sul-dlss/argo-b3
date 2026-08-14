# frozen_string_literal: true

FactoryBot.define do
  factory :content_file_binary do
    content
    file_location { 'attached' }
    filepath { 'image1.tif' }
    basename { 'image1' }
    extname { '.tif' }
  end
end
