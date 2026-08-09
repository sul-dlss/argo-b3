# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DruidValidator do
  let(:validatable_class) do
    Class.new do
      include ActiveModel::Validations

      attr_accessor :druid

      validates :druid, druid: true

      def self.name
        'ValidatableForDruid'
      end
    end
  end
  let(:record) { validatable_class.new }

  it 'is valid for a well-formed druid' do
    record.druid = 'druid:bc123df4567'
    expect(record).to be_valid
  end

  it 'is invalid when the druid prefix is missing' do
    record.druid = 'bc123df4567'
    expect(record).not_to be_valid
  end

  it 'is invalid when a letter position contains an excluded letter (vowel or l)' do
    record.druid = 'druid:ac123df4567'
    expect(record).not_to be_valid
  end

  it 'is invalid when there are too few digits' do
    record.druid = 'druid:bc12df4567'
    expect(record).not_to be_valid
  end

  it 'is invalid when there are too many digits' do
    record.druid = 'druid:bc1234df4567'
    expect(record).not_to be_valid
  end

  it 'is invalid when the letters are uppercase' do
    record.druid = 'druid:BC123DF4567'
    expect(record).not_to be_valid
  end

  it 'is invalid for nil' do
    record.druid = nil
    expect(record).not_to be_valid
  end

  it 'is invalid for a blank string' do
    record.druid = ''
    expect(record).not_to be_valid
  end

  it 'is invalid when there is leading or trailing whitespace' do
    record.druid = ' druid:bc123df4567 '
    expect(record).not_to be_valid
  end

  it 'adds an error message to the attribute' do
    record.druid = 'invalid'
    record.valid?
    expect(record.errors[:druid]).to include('is not a valid druid')
  end
end
