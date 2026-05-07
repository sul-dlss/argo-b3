# frozen_string_literal: true

class StructuralEditor::FileSetsCardComponent < ApplicationComponent
  def initialize(file_sets:)
    @file_sets = file_sets
    super()
  end

  attr_reader :file_sets

  def content_type_for(file_set_hash)
    file_set_hash[:type].delete_prefix('https://cocina.sul.stanford.edu/models/resources/')
  end
end
