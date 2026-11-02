# frozen_string_literal: true

# The json viewer renders into a shadow DOM, collapsed below the top level, so the description is expanded first.
def expect_cocina_json_title(title)
  json_viewer = find('#cocina-model-pane andypf-json-viewer').shadow_root
  json_viewer.find('.key', exact_text: 'description').click(:shift)
  expect(json_viewer).to have_css('span', exact_text: "\"#{title}\"")
end
