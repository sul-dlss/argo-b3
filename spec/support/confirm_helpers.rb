# frozen_string_literal: true

# Clicks via JS: a layout shift can make a positional click miss, so Turbo never shows the confirm.
def click_and_accept_confirm(message, element)
  accept_confirm(message) { page.execute_script('arguments[0].click()', element) }
end
