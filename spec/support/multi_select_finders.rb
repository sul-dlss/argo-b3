# frozen_string_literal: true

# Helpers for driving tom-select multi-select fields, which hide the underlying
# select element. See app/javascript/controllers/multi_select_controller.js.

def find_multi_select(label)
  find('label', text: label, exact_text: true).sibling('.ts-wrapper')
end

def select_multi_option(option_label, from:)
  find_multi_select(from).find('.ts-control input').set(option_label)
  find('.ts-dropdown .option', text: option_label, exact_text: true).click
end

# Type a partial option label and commit the highlighted match with the given key.
def select_multi_option_with_key(query, from:, key:)
  input = find_multi_select(from).find('.ts-control input')
  input.send_keys(query)
  # Wait for the query to be filtered and highlighted, or the key commits whatever was active before.
  find('.ts-dropdown .option.active', text: query)
  input.send_keys(key)
end

def remove_first_multi_option(from:)
  find_multi_select(from).first('.item .remove').click
end

def find_multi_select_items(from:)
  find_multi_select(from).all('.item')
end
