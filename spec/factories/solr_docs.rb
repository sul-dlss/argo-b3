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
      apo_druid { generate(:unique_druid) }
      projects { [] }
    end

    initialize_with do
      {
        Search::Fields::ID => druid,
        Search::Fields::BARE_DRUID => DruidSupport.bare_druid_from(druid),
        Search::Fields::TITLE => title,
        Search::Fields::OBJECT_TYPE => [object_type],
        Search::Fields::APO_ID => [apo_druid],
        Search::Fields::PROJECT_TAGS => explode_tag_hierarchy(tags: projects),
        Search::Fields::PROJECT_HIERARCHICAL_TAGS => explode_tag_hierarchy(tags: projects, as_hierarchical: true),
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
    end

    initialize_with do
      {
        Search::Fields::ID => druid,
        Search::Fields::BARE_DRUID => DruidSupport.bare_druid_from(druid),
        Search::Fields::TITLE => title,
        Search::Fields::OBJECT_TYPE => [object_type],
        Search::Fields::PROJECT_TAGS => explode_tag_hierarchy(tags: projects),
        Search::Fields::PROJECT_HIERARCHICAL_TAGS => explode_tag_hierarchy(tags: projects, as_hierarchical: true),
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
end

# This is similar to code in DSA AdministrativeTagIndexer.
def explode_tag_hierarchy(tags:, as_hierarchical: false)
  [].tap do |exploded_tags|
    tags.each do |tag|
      tag_parts = tag.split(' : ')
      1.upto(tag_parts.count).each do |i|
        joined_parts = tag_parts.take(i).join(' : ')
        exploded_tags << if as_hierarchical
                           leaf_or_branch_indicator = i == tag_parts.count ? '-' : '+'
                           "#{i}|#{joined_parts}|#{leaf_or_branch_indicator}"
                         else
                           joined_parts
                         end
      end
    end
  end
end
