# frozen_string_literal: true

# Stubs two APOs that the user can register with, for specs of applying APO defaults to a form.
# "Another APO" is listed first, so it is initially selected. "My APO" has defaults for view and download
# (location-based), location (m&m), copyright, and license (CC Attribution 4.0 International), but not
# use and reproduction. "Another APO" has defaults only for view (stanford) and download (none).
#
# Requires `workgroup`, a group of the signed in user.
#
# Usage:
#   include_context 'with APOs with defaults'
RSpec.shared_context 'with APOs with defaults' do
  let(:apo_druid) { 'druid:bc123df4567' }
  let(:apo_title) { 'My APO' }
  let(:apo_cocina_object) do
    build(:admin_policy_with_metadata, id: apo_druid).new(
      administrative: {
        hasAdminPolicy: 'druid:hv992ry2431',
        hasAgreement: 'druid:hp308wm0436',
        accessTemplate: {
          view: 'location-based',
          download: 'location-based',
          location: 'm&m',
          copyright: 'Copyright © Stanford University.',
          license: 'https://creativecommons.org/licenses/by/4.0/legalcode'
        }
      }
    )
  end

  let(:other_apo_druid) { 'druid:xz987wv6543' }
  let(:other_apo_title) { 'Another APO' }
  let(:other_apo_cocina_object) do
    build(:admin_policy_with_metadata, id: other_apo_druid).new(
      administrative: {
        hasAdminPolicy: 'druid:hv992ry2431',
        hasAgreement: 'druid:hp308wm0436',
        accessTemplate: { view: 'stanford', download: 'none' }
      }
    )
  end

  before do
    create(:permission, :edit, workgroup:, target_druid: apo_druid)
    create(:permission, :edit, workgroup:, target_druid: other_apo_druid)

    allow(Searchers::AdminPolicyList).to receive(:call).and_return([[other_apo_title, other_apo_druid],
                                                                    [apo_title, apo_druid]])
    cocina_objects = { apo_druid => apo_cocina_object, other_apo_druid => other_apo_cocina_object }
    allow(Sdr::Repository).to receive(:find) { |druid:| cocina_objects.fetch(druid) }
  end
end
