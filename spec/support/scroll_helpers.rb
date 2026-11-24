# frozen_string_literal: true

# Helpers for asserting where a page is scrolled to, e.g., that it opens at the results of a check.
module ScrollHelpers
  # @return [Boolean] true if the page is scrolled so that the first element matching selector is at the top of the
  #   window, or as near it as the page allows (i.e., scrolled to the bottom)
  def scrolled_to?(selector)
    page.evaluate_script(<<~JS)
      document.querySelector(#{selector.to_json}).getBoundingClientRect().top <= 1 ||
        window.scrollY + window.innerHeight >= document.documentElement.scrollHeight - 1
    JS
  end

  # @return [Float] how far in px the page is scrolled down
  def window_scroll_y
    page.evaluate_script('window.scrollY')
  end

  # Waits for a page that opens at an element (see focus_on_load_controller.js) to have had the chance to do so,
  # so that asserting that it opened at the top is meaningful.
  def wait_for_animation_frame
    page.evaluate_async_script('requestAnimationFrame(() => requestAnimationFrame(arguments[0]))')
  end

  RSpec.configure do |config|
    config.include self, type: :system
  end
end
