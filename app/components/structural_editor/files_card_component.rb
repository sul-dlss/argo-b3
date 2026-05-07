# frozen_string_literal: true

class StructuralEditor::FilesCardComponent < ApplicationComponent
  def initialize(file_sets:)
    @file_sets = file_sets
    super()
  end

  def files
    file_sets.flat_map do |file_set_hash|
      file_set_hash[:structural][:contains].map do |file_hash|
        file_hash[:filename]
      end
    end
  end

  attr_reader :file_sets
end
