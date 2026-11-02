# frozen_string_literal: true

require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../../lib/rubocop/cop/argo_b3/format_datetime'

RSpec.describe RuboCop::Cop::ArgoB3::FormatDatetime, :config do
  it 'registers an offense for strftime' do
    expect_offense(<<~RUBY)
      created_at.strftime('%Y-%m-%d')
                 ^^^^^^^^ Render dates and times with `format_datetime` and a format from `time.formats`.
    RUBY
  end

  it 'registers an offense for to_fs with a time format' do
    expect_offense(<<~RUBY)
      created_at&.to_fs(:long)
                  ^^^^^ Render dates and times with `format_datetime` and a format from `time.formats`.
    RUBY
  end

  it 'registers an offense for to_formatted_s without a format' do
    expect_offense(<<~RUBY)
      created_at.to_formatted_s
                 ^^^^^^^^^^^^^^ Render dates and times with `format_datetime` and a format from `time.formats`.
    RUBY
  end

  it 'does not register an offense for to_fs with a number format' do
    expect_no_offenses(<<~RUBY)
      count.to_fs(:delimited)
    RUBY
  end

  it 'does not register an offense for format_datetime' do
    expect_no_offenses(<<~RUBY)
      helpers.format_datetime(created_at, format: :date_only)
    RUBY
  end
end
