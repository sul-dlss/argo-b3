# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake.

require_relative 'config/application'

Rails.application.load_tasks

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new

  # clear the default task injected by rspec
  task(:default).clear

  task default: %i[lint spec]
rescue LoadError
  # should only be here when gem group development and test aren't installed
end
