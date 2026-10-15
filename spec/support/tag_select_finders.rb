# frozen_string_literal: true

# Helpers for driving tom-select tag fields, which hide the underlying text input.
# See app/javascript/controllers/tag_select_controller.js.

# Found by the name of the underlying text input.
def find_tag_select(field_name)
  find_field(field_name, visible: :all).sibling('.ts-wrapper')
end

# The input that tom-select renders for typing.
def find_tag_select_input(field_name)
  find_tag_select(field_name).find('.ts-control input')
end

# Enter a tag that is not one of the suggestions.
def fill_in_tag(field_name, with:)
  input = find_tag_select_input(field_name)
  input.set(with)
  input.send_keys(:tab)
end

def select_tag_suggestion(suggestion, query:, field_name:)
  find_tag_select_input(field_name).set(query)
  find('.ts-dropdown .option', text: suggestion, exact_text: true).click
end

def find_tag_select_item(field_name)
  find_tag_select(field_name).find('.ts-control .item')
end
