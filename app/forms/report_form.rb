# frozen_string_literal: true

# Form object for report parameters
class ReportForm < ApplicationForm
  attribute :source, :string, default: 'druids'
  attribute :druid_list, :string
  attribute :fields, array: true, default: []
end
