# frozen_string_literal: true

namespace :development do
  desc 'Bootstrap an AdminPolicy for local development use'
  task :bootstrap_apo, [:title] => :environment do |_t, args|
    raise 'This task can only be run in the development environment' unless Rails.env.development?

    admin_policy = CocinaModels::AdminPolicy.new(
      admin_policy_druid: 'druid:hv992ry2431',
      agreement_druid: 'druid:hp308wm0436',
      access_view: 'world',
      access_download: 'world',
      description_hash: { title: [{ value: args[:title] }] }
    )
    admin_policy.create!(user_name: 'auser')

    puts admin_policy.druid
  end
end
