class StructuralForm < ApplicationForm
  attribute :content_type, :string, default: 'object'
  attribute :filenames, :string
  attribute :instructions, :string
end
