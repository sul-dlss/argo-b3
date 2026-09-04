# frozen_string_literal: true

module Impersonation
  # Handles deriving available workgroups and reading/writing impersonated workgroups from encrypted cookies.
  class Workgroups
    COOKIE_KEY = :impersonated_workgroups
    ADMIN_GROUP_SUFFIX = '/administrator'

    class << self
      def available_for_user(user:)
        user.groups
            .map { |group| group.delete_suffix(ADMIN_GROUP_SUFFIX) }
            .compact_blank
            .uniq
            .sort
      end

      def from_cookie(cookies:)
        Array(cookies.encrypted[COOKIE_KEY]).compact_blank
      end

      def update_cookie(cookies:, groups:)
        sanitized_groups = Array(groups).compact_blank.uniq.sort

        if sanitized_groups.present?
          cookies.encrypted[COOKIE_KEY] = {
            value: sanitized_groups,
            httponly: true,
            same_site: :lax
          }
        else
          clear_cookie(cookies:)
        end
      end

      def clear_cookie(cookies:)
        cookies.encrypted[COOKIE_KEY] = nil
        cookies.delete(COOKIE_KEY)
      end
    end
  end
end
