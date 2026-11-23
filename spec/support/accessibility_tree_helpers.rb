# frozen_string_literal: true

# Reads what Chrome exposes to screen readers, in Selenium system specs.
module AccessibilityTreeHelpers
  CLICK_EVENT_TYPES = %w[click mousedown mouseup].freeze

  # @return [Hash] the accessibility tree's role, name, and child roles for the first element matching the selector
  def accessibility_node(selector)
    backend_node_id = backend_node_id(selector)
    nodes = cdp('Accessibility.getPartialAXTree', backendNodeId: backend_node_id, fetchRelatives: true)['nodes']
    node = nodes.find { |candidate| candidate['backendDOMNodeId'] == backend_node_id }
    {
      role: node.dig('role', 'value'),
      name: node.dig('name', 'value'),
      child_roles: nodes.select { |candidate| candidate['parentId'] == node['nodeId'] }
                        .map { |child| child.dig('role', 'value') }
    }
  end

  # @return [Array<String>] the element and its ancestors below <body> that listen for clicks, e.g., "th#id.class"
  def click_listener_elements(selector)
    object_id = cdp('Runtime.evaluate', expression: "document.querySelector(#{selector.to_json})")
                .dig('result', 'objectId')
    elements = []
    while object_id
      description = call_function_on(object_id, DESCRIBE_ELEMENT_JS, returnByValue: true).dig('result', 'value')
      break if description.nil?

      listener_types = cdp('DOMDebugger.getEventListeners', objectId: object_id)['listeners'].pluck('type')
      elements << description if listener_types.intersect?(CLICK_EVENT_TYPES)
      object_id = call_function_on(object_id, 'function() { return this.parentElement }').dig('result', 'objectId')
    end
    elements
  end

  DESCRIBE_ELEMENT_JS = <<~JS
    function() {
      if (this === document.body) return null
      return [this.tagName.toLowerCase(), this.id && `#${this.id}`, ...[...this.classList].map((name) => `.${name}`)].join('')
    }
  JS

  private

  def backend_node_id(selector)
    root_id = cdp('DOM.getDocument', depth: 0).dig('root', 'nodeId')
    node_id = cdp('DOM.querySelector', nodeId: root_id, selector:)['nodeId']
    cdp('DOM.describeNode', nodeId: node_id).dig('node', 'backendNodeId')
  end

  def call_function_on(object_id, function_declaration, **params)
    cdp('Runtime.callFunctionOn', objectId: object_id, functionDeclaration: function_declaration, **params)
  end

  def cdp(command, **params)
    page.driver.browser.execute_cdp(command, **params)
  end
end

RSpec.configure do |config|
  config.include AccessibilityTreeHelpers, type: :system
end
