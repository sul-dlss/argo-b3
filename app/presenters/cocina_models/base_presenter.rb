# frozen_string_literal: true

module CocinaModels
  # Shared presenter behavior for Cocina models.
  class BasePresenter < SimpleDelegator
    def save!(*)
      raise 'save! is not allowed on a presenter.'
    end

    # @return [Hash] the cocina object as a hash with blank values removed
    def to_h
      CocinaDisplay::Utils.deep_compact_blank(cocina_object.to_h)
    end

    def cocina_object
      previous_cocina_object
    end

    def cocina_display
      @cocina_display ||= CocinaDisplay::CocinaRecord.new(cocina_object.to_h.deep_stringify_keys)
    end

    # Immutable fields or convenience methods belong in the presenter; otherwise, they should be in the model.

    # @return [String, nil] druid of the admin policy
    def admin_policy_druid
      cocina_object.administrative.hasAdminPolicy
    end

    # @return [String] joined contributor display names
    def contributors
      cocina_display.contributors.map(&:display_name).join('; ')
    end

    # @return [String] display title
    def title
      cocina_display.display_title
    end
  end
end
