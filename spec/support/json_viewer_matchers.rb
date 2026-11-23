# frozen_string_literal: true

# The json viewer renders into a shadow DOM, collapsed below the top level, so it is expanded first.
# Collapsing and expanding again checks that the buttons work after the viewer's own expanded state changes.
# The viewer is a focusable, labelled region, so keyboard and screen reader users can reach it.
def expect_cocina_json_title(title)
  pane = find_by_id('cocina-model-pane')
  json_viewer = pane.find('andypf-json-viewer[role="region"][tabindex="0"][aria-label="Cocina JSON"]').shadow_root
  pane.click_button 'Expand all'
  expect(json_viewer).to have_css('span', exact_text: "\"#{title}\"")
  pane.click_button 'Collapse all'
  expect(json_viewer).to have_no_css('span', exact_text: "\"#{title}\"")
  pane.click_button 'Expand all'
  expect(json_viewer).to have_css('span', exact_text: "\"#{title}\"")
  expect_json_viewer_focused_after(pane, 'Collapse all')
end

# The viewer follows the button in the tab order.
def expect_json_viewer_focused_after(container, button_label)
  container.find_button(button_label).send_keys(:tab)
  expect(container).to have_css('andypf-json-viewer:focus')
end
