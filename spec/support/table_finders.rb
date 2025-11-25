# frozen_string_literal: true

def find_table(table_id)
  page.find("table##{table_id}")
end

def find_table_value_cell(table_id, row_label)
  table = find_table(table_id)
  row = table.all('tr').find { |tr| tr.has_css?('th', text: row_label) }
  row.find('td')
end
