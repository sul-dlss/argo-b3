# frozen_string_literal: true

module DescriptionEditor
  class DiffComponent < ApplicationComponent
    def initialize(diff:)
      @diff = diff
    end

    private

    attr_reader :diff

    def change_type
      case diff[0]
      when '+'
        'Added'
      when '-'
        'Removed'
      else
        'Changed'
      end
    end

    def path
      diff[1]
    end

    def change_value
      diff[2]
    end
  end
end
