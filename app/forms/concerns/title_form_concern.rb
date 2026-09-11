# frozen_string_literal: true

# Concern for the title attribute used by forms.
module TitleFormConcern
  extend ActiveSupport::Concern

  included do
    attribute :title, :string
    normalizes :title, with: ->(title) { title.strip }
  end
end
