# frozen_string_literal: true

# The json viewer renders into a shadow DOM, collapsed below the top level, so it is expanded first.
# Collapsing and expanding again checks that the buttons work after the viewer's own expanded state changes.
def expect_cocina_json_title(title)
  pane = find_by_id('cocina-model-pane')
  json_viewer = pane.find('andypf-json-viewer').shadow_root
  pane.click_button 'Expand all'
  expect(json_viewer).to have_css('span', exact_text: "\"#{title}\"")
  pane.click_button 'Collapse all'
  expect(json_viewer).to have_no_css('span', exact_text: "\"#{title}\"")
  pane.click_button 'Expand all'
  expect(json_viewer).to have_css('span', exact_text: "\"#{title}\"")
end
