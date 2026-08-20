# frozen_string_literal: true

# Cocina::RSpec::Factories (from the cocina-models gem) supports :dro, :collection, and
# :admin_policy, but not :agreement (an agreement is a DRO subtype). These factories fill
# that gap, reusing the gem's own property builder with the agreement object type.
def build_agreement_cocina_object(id:, admin_policy_id:, title:, source_id:)
  Cocina::Models.build(
    Cocina::RSpec::Factories.build_dro_properties(
      id:, type: Cocina::Models::ObjectType.agreement, version: 1, title:, source_id:, admin_policy_id:
    )
  )
end

FactoryBot.define do
  factory :agreement, class: 'Cocina::Models::DRO' do
    transient do
      id { 'druid:bc234fg5678' }
      admin_policy_id { 'druid:hv992ry2431' }
      title { 'factory agreement title' }
      source_id { 'sul:1234' }
    end

    skip_create
    initialize_with { build_agreement_cocina_object(id:, admin_policy_id:, title:, source_id:) }
  end

  factory :agreement_with_metadata, class: 'Cocina::Models::DROWithMetadata' do
    transient do
      id { 'druid:bc234fg5678' }
      admin_policy_id { 'druid:hv992ry2431' }
      title { 'factory agreement title' }
      source_id { 'sul:1234' }
    end

    skip_create
    initialize_with do
      Cocina::Models.with_metadata(build_agreement_cocina_object(id:, admin_policy_id:, title:, source_id:), 'abc123')
    end
  end
end
