# frozen_string_literal: true

module StructuralEditor
  class CocinaStructuralCardComponent < ApplicationComponent
    def initialize(file_sets:)
      @file_sets = file_sets
      super()
    end

    private

    attr_reader :file_sets
  end
end
