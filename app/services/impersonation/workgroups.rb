# frozen_string_literal: true

module Impersonation
  # Handles deriving available workgroups and reading/writing impersonated workgroups from encrypted cookies.
  class Workgroups
    COOKIE_KEY = :impersonated_workgroups
    ADMIN_GROUP_SUFFIX = '/administrator'

    class << self
      # Returns a normalized list of workgroups a user can impersonate.
      #
      # Removes any trailing administrator suffix, drops blanks, de-duplicates,
      # and sorts for stable display in the impersonation UI.
      #
      # @param user [User] the currently authenticated user
      # @return [Array<String>] sorted unique impersonable workgroups
      def available_for_user(user:)
        user.groups
            .map { |group| group.delete_suffix(ADMIN_GROUP_SUFFIX) }
            .compact_blank
            .uniq
            .sort
      end

      # Reads impersonated workgroups from the encrypted cookie.
      #
      # Always returns an array and removes blank entries.
      #
      # @param cookies [ActionDispatch::Cookies::CookieJar] request cookie jar
      # @return [Array<String>] impersonated workgroups from cookie
      def from_cookie(cookies:)
        Array(cookies.encrypted[COOKIE_KEY]).compact_blank
      end

      # Persists the selected impersonated workgroups in an encrypted cookie.
      #
      # Values are normalized (blank removal, uniqueness, sorted). If the
      # resulting list is empty, impersonation is cleared by deleting the cookie.
      #
      # @param cookies [ActionDispatch::Cookies::CookieJar] request cookie jar
      # @param groups [Array<String>, String, nil] selected workgroup values
      # @return [void]
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

      # Removes the impersonation cookie and clears any encrypted value.
      #
      # @param cookies [ActionDispatch::Cookies::CookieJar] request cookie jar
      # @return [void]
      def clear_cookie(cookies:)
        cookies.encrypted[COOKIE_KEY] = nil
        cookies.delete(COOKIE_KEY)
      end
    end
  end
end
