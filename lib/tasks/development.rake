# frozen_string_literal: true

namespace :development do
  desc 'Bootstrap an AdminPolicy for local development use (optional: TITLE=...)'
  task bootstrap_apo: :environment do
    raise 'This task can only be run in the development environment' unless Rails.env.development?

    title = ENV.fetch('TITLE') { "#{Faker::Creature::Animal.name.titleize} #{Faker::Food.dish} APO" }

    admin_policy = CocinaModels::AdminPolicy.new(
      # This contains arbitrary hardcoded values; in the future, may want to make more flexible.
      apo_druid: 'druid:hv992ry2431',
      agreement_druid: 'druid:hp308wm0436',
      access_view: 'world',
      access_download: 'world',
      description_hash: { title: [{ value: title }] }
    )
    admin_policy.create!(user_name: 'auser')

    puts "#{title} (#{admin_policy.druid})"
  end

  desc 'Bootstrap a Collection for local development use (optional: TITLE=...)'
  task :bootstrap_collection, [:apo_druid] => :environment do |_t, args|
    raise 'This task can only be run in the development environment' unless Rails.env.development?

    apo_druid = args.fetch(:apo_druid) { raise 'APO druid is required, e.g., bootstrap_collection[druid:bc123df4567]' }
    title = ENV.fetch('TITLE') { "#{Faker::Educator.subject} #{Faker::University.suffix} Collection" }

    collection = CocinaModels::Collection.new(
      apo_druid:,
      source_id: "development:#{SecureRandom.uuid}",
      access_view: 'world',
      description_hash: { title: [{ value: title }] }
    )
    collection.create!(user_name: 'auser')

    puts "#{title} (#{collection.druid})"
  end
end
