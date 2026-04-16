# frozen_string_literal: true

RSpec::Matchers.define :have_table_value do |table_id, row_label, expected_value|
  match do |actual|
    row = actual.find("table##{table_id}").all('tr').find { |tr| tr.has_css?('th', text: row_label) }
    next false unless row

    row.has_css?('td', text: expected_value)
  end
end

RSpec::Matchers.define :have_table_caption do |table_id, expected_caption|
  match do |actual|
    caption = actual.find("table##{table_id}").find('caption')
    caption.has_text?(expected_caption)
  end
end
