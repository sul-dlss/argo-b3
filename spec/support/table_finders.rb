# frozen_string_literal: true

def find_table(table_id)
  page.find("table##{table_id}")
end

def find_table_value_cell(table_id, row_label)
  find_table_row(table_id, row_label).find('td')
end

def find_table_row(table_id, row_label)
  table = find_table(table_id)
  table.find(:xpath, ".//tr[./th[normalize-space()='#{row_label}']]")
end
