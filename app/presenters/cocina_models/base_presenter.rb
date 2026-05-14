# frozen_string_literal: true

module CocinaModels
  # Base presenter for a Cocina model.
  # Note that a SimpleDelegator will delegate to whatever object is passed to the constructor.
  # See the subclasses for the expected object types.
  class BasePresenter < SimpleDelegator
    private

    def humanize_access_value(value)
      value == 'location-based' ? 'Location' : value.capitalize
    end
  end
end
