# frozen_string_literal: true

require 'json'
require 'open3'

# Runs the project's herb linter (custom rules in .herb/rules) against a fixture template.
RSpec.describe 'argo-b3-no-erb-in-attribute-value herb rule' do
  let(:root) { File.expand_path('../..', __dir__) }
  let(:fixture) { 'spec/fixtures/herb/erb_in_attribute_value.html.erb' }

  let(:offense_lines) do
    output, = Open3.capture2('yarn', '--silent', 'herb-lint', fixture, '--force', '--format', 'json', chdir: root)
    JSON.parse(output)['offenses']
        .select { |offense| offense['code'] == 'argo-b3-no-erb-in-attribute-value' }
        .map { |offense| offense.dig('location', 'start', 'line') }
  end

  it 'flags ERB output and control flow in attribute values but not tag helpers or static values' do
    expect(offense_lines).to eq [1, 2, 2, 3]
  end
end
