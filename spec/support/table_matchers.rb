# frozen_string_literal: true

RSpec::Matchers.define :have_table_value do |table_id, row_label, expected_value|
  match do |actual|
    table = actual.find("table##{table_id}")
    row = table.find(:xpath, ".//tr[./th[normalize-space()='#{row_label}']]")
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
