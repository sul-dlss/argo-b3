# frozen_string_literal: true

# Form object for a project tag on an item
class ProjectTagForm < ApplicationForm
  PROJECT_TAG_PREFIX = 'Project : '

  attribute :tag, :string
  # Tolerate a pasted tag that includes prefix.
  normalizes :tag, with: ->(value) { value.strip.delete_prefix(PROJECT_TAG_PREFIX).strip.presence }
end
