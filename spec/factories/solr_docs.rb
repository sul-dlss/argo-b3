# frozen_string_literal: true

# These are search-only fields so are not in Search::Fields.
FULL_TITLE_UNSTEMMED = 'full_title_unstemmed_im'
FULL_TITLE = 'full_title_tenim'

FactoryBot.define do
  # Note that these factories are independent because they each
  # may have different fields.
  factory :solr_item, class: 'Hash', traits: [:with_projects] do
    transient do
      druid { generate(:unique_druid) }
      sequence(:title) { |n| "Test Item #{n}" }
      object_type { 'item' }
      content_type { 'book' }
      apo_druid { generate(:unique_druid) }
      projects { [] }
      tags { [] }
      sequence(:ticket) { |n| "TESTREQ-#{n}" }
      workflows { [] }
      mimetypes { ['application/pdf', 'image/jpeg'] }
      released_to_earthworks { true }
      access_rights { 'dark' }
      earliest_accessioned_date { 1.year.ago }
      collection_titles { ['David Rumsey Map Collection'] }
      admin_policy_titles { ['University Archives'] }
      dates { ['2001'] }
      topics { ['Marching bands'] }
      regions { ['Palo Alto'] }
      genres { ['Maps'] }
      languages { ['English'] }
    end

    initialize_with do
      {
        Search::Fields::ID => druid,
        Search::Fields::BARE_DRUID => DruidSupport.bare_druid_from(druid),
        Search::Fields::TITLE => title,
        Search::Fields::OBJECT_TYPES => [object_type],
        Search::Fields::CONTENT_TYPES => [content_type],
        Search::Fields::APO_DRUID => [apo_druid],
        Search::Fields::PROJECTS_EXPLODED => explode_hierarchy(values: projects),
        Search::Fields::PROJECTS_HIERARCHICAL => explode_hierarchy(values: projects, as_hierarchical: true),
        Search::Fields::OTHER_TAGS => explode_hierarchy(values: tags),
        Search::Fields::OTHER_HIERARCHICAL_TAGS => explode_hierarchy(values: tags, as_hierarchical: true),
        Search::Fields::TICKETS => [ticket],
        Search::Fields::WPS_WORKFLOWS => explode_hierarchy(values: workflows, delimiter: ':'),
        Search::Fields::WPS_HIERARCHICAL_WORKFLOWS => explode_hierarchy(values: workflows, as_hierarchical: true,
                                                                        delimiter: ':'),
        Search::Fields::MIMETYPES => mimetypes,
        Search::Fields::RELEASED_TO_EARTHWORKS => released_to_earthworks ? Time.now.utc.iso8601 : nil,
        Search::Fields::ACCESS_RIGHTS => [access_rights],
        Search::Fields::EARLIEST_ACCESSIONED_DATE => earliest_accessioned_date.utc.iso8601,
        Search::Fields::COLLECTION_TITLES => collection_titles,
        Search::Fields::APO_TITLE => admin_policy_titles,
        Search::Fields::PUBLICATION_DATE => dates,
        Search::Fields::TOPICS => topics,
        Search::Fields::REGIONS => regions,
        Search::Fields::GENRES => genres,
        Search::Fields::LANGUAGES => languages,
        Search::Fields::PURL => "https://purl.stanford.edu/#{DruidSupport.bare_druid_from(druid)}",
        FULL_TITLE_UNSTEMMED => title,
        FULL_TITLE => title
      }
    end

    to_create do |solr_doc|
      Search::SolrFactory.call.add(solr_doc)
      Search::SolrFactory.call.commit
    end

    trait :google_book do
      transient do
        apo_druid { Settings.google_books_apo }
      end
    end

    trait :agreement do
      transient do
        object_type { 'agreement' }
      end
    end
  end

  factory :solr_collection, class: 'Hash', traits: [:with_projects] do
    transient do
      druid { generate(:unique_druid) }
      sequence(:title) { |n| "Test Collection #{n}" }
      object_type { 'collection' }
      projects { [] }
      tags { [] }
      workflows { [] }
      access_rights { 'dark' }
    end

    initialize_with do
      {
        Search::Fields::ID => druid,
        Search::Fields::BARE_DRUID => DruidSupport.bare_druid_from(druid),
        Search::Fields::TITLE => title,
        Search::Fields::OBJECT_TYPES => [object_type],
        Search::Fields::PROJECTS_EXPLODED => explode_hierarchy(values: projects),
        Search::Fields::PROJECTS_HIERARCHICAL => explode_hierarchy(values: projects, as_hierarchical: true),
        Search::Fields::OTHER_TAGS => explode_hierarchy(values: tags),
        Search::Fields::OTHER_HIERARCHICAL_TAGS => explode_hierarchy(values: tags, as_hierarchical: true),
        Search::Fields::WPS_WORKFLOWS => explode_hierarchy(values: workflows, delimiter: ':'),
        Search::Fields::WPS_HIERARCHICAL_WORKFLOWS => explode_hierarchy(values: workflows, as_hierarchical: true,
                                                                        delimiter: ':'),
        Search::Fields::ACCESS_RIGHTS => [access_rights],
        FULL_TITLE_UNSTEMMED => title,
        FULL_TITLE => title
      }
    end

    to_create do |solr_doc|
      Search::SolrFactory.call.add(solr_doc)
      Search::SolrFactory.call.commit
    end
  end

  trait :with_projects do
    transient do
      projects { ['Project 1', 'Project 2 : Project 2a'] }
    end
  end

  trait :with_tags do
    transient do
      tags { ['Tag 1', 'Tag 2 : Tag 2a'] }
    end
  end

  trait :with_workflows do
    transient do
      workflows { ['accessionWF:shelve:completed', 'accessionWF:technical-metadata:skipped'] }
    end
  end
end

# This is similar to code in DSA AdministrativeTagIndexer.
def explode_hierarchy(values:, as_hierarchical: false, delimiter: ' : ')
  [].tap do |exploded_values|
    values.each do |value|
      value_parts = value.split(delimiter)
      1.upto(value_parts.count).each do |i|
        joined_parts = value_parts.take(i).join(delimiter)
        exploded_values << if as_hierarchical
                             leaf_or_branch_indicator = i == value_parts.count ? '-' : '+'
                             "#{i}|#{joined_parts}|#{leaf_or_branch_indicator}"
                           else
                             joined_parts
                           end
      end
    end
  end
end
