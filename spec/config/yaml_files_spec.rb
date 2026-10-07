# frozen_string_literal: true

require 'rails_helper'

# Catches YAML mistakes that otherwise only surface at runtime (e.g., a failed boot or a broken link in the UI).
RSpec.describe 'YAML config files' do # rubocop:disable RSpec/DescribeClass
  let(:locale_paths) { Rails.root.glob('config/locales/**/*.yml') }
  let(:settings_paths) { [Rails.root.join('config/settings.yml'), *Rails.root.glob('config/settings/*.yml')] }

  # Returns [key_path, value] pairs for every string value in nested hashes / arrays.
  def string_values(node, key_path = [])
    case node
    when Hash then node.flat_map { |key, value| string_values(value, key_path + [key]) }
    when Array then node.each_with_index.flat_map { |value, index| string_values(value, key_path + [index]) }
    when String then [[key_path.join('.'), node]]
    else []
    end
  end

  def load_locale(path)
    YAML.safe_load_file(path, aliases: true)
  end

  # Returns "file: key.path" for each locale string value for which the block returns true.
  def locale_offenses
    locale_paths.flat_map do |path|
      string_values(load_locale(path)).filter_map do |key_path, value|
        "#{path.basename}: #{key_path}" if yield(key_path, value)
      end
    end
  end

  it 'parses the locale files' do
    locale_paths.each do |path|
      expect { load_locale(path) }.not_to raise_error, "#{path} is not valid YAML"
    end
  end

  it 'parses the settings files (after rendering ERB, as the config gem does)' do
    settings_paths.each do |path|
      expect { YAML.safe_load(ERB.new(path.read).result, aliases: true) }
        .not_to raise_error, "#{path} is not valid YAML"
    end
  end

  it 'does not have escaped quotes in locale strings' do
    # In block scalars (e.g., >- or |) a backslash is literal, so \" ends up in the rendered output.
    offenses = locale_offenses { |_key_path, value| value.include?('\\"') }

    expect(offenses).to be_empty, "Locale strings contain a literal \\\":\n#{offenses.join("\n")}"
  end

  it 'quotes href attributes in html locale strings' do
    # Catches href=\"...\" and href=%22...%22, which browsers treat as relative URLs.
    offenses = locale_offenses { |key_path, value| key_path.end_with?('html') && value.match?(/href=(?!["'])/) }

    expect(offenses).to be_empty, "Locale html strings have an improperly quoted href:\n#{offenses.join("\n")}"
  end
end
