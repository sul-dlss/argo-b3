# frozen_string_literal: true

module Impersonation
  # Lists the workgroups available for impersonation and reads/writes the impersonated workgroups cookie.
  class Workgroups
    COOKIE_KEY = :impersonated_workgroups
    # Workgroups offered for impersonation; update when a new team starts using Argo.
    WORKGROUPS = %w[
      sdr:3d-staff
      sdr:accessioning
      sdr:acquisitions-staff
      sdr:admin-docs
      sdr:admin-temporary
      sdr:administrator
      sdr:administrator-role
      sdr:api-authorized-users
      sdr:argo-access
      sdr:argo-message-editors
      sdr:argo_administrators
      sdr:ars-staff
      sdr:art-staff
      sdr:berman-archive
      sdr:bibliographers-staff
      sdr:big_local_data
      sdr:cantor-staff
      sdr:catalhoyuk
      sdr:cesta-admin-staff
      sdr:chs-staff
      sdr:cidr-staff
      sdr:conservation-staff
      sdr:curator-staff
      sdr:developer
      sdr:development-hourlies
      sdr:dpg-hourlies
      sdr:dpg-staff
      sdr:eal-staff
      sdr:eresources-staff
      sdr:etds-quarterly-reports
      sdr:etds-registrar-staff
      sdr:etds-sul-staff
      sdr:forensics-staff
      sdr:gb-ill-staff
      sdr:geospecimen-staff
      sdr:gsb-library
      sdr:hoover-staff
      sdr:hopkins-staff
      sdr:hydrus-collection-managers
      sdr:hydrus-manager-role
      sdr:hydrus-service-team
      sdr:hydrus-staff
      sdr:lanciani-archive
      sdr:lane-staff
      sdr:law-staff
      sdr:lockss-staff
      sdr:manager-role
      sdr:map-hourlies
      sdr:map-staff
      sdr:martin-wong
      sdr:media-microtext
      sdr:metadata-staff
      sdr:music-staff
      sdr:nash-photo-archive
      sdr:office-tech-license
      sdr:osc
      sdr:otl
      sdr:parker-staff
      sdr:production-coordinators
      sdr:psm-staff
      sdr:sa-print-collection-staff
      sdr:sagr-staff
      sdr:serg-staff
      sdr:service-manager
      sdr:service-team
      sdr:smpl-staff
      sdr:sohp-staff
      sdr:spec-staff
      sdr:staff
      sdr:suac-staff
      sdr:summer-student
      sdr:sup-staff
      sdr:sustaining-websites
      sdr:twala
      sdr:ua-students
      sdr:url-managers
      sdr:viewer-role
      sdr:was-staff
    ].freeze

    class << self
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
