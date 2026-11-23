# frozen_string_literal: true

# Reads what Chrome exposes to screen readers, in Selenium system specs.
# See the screen-reader-bug skill (.claude/skills/screen-reader-bug/SKILL.md).
module AccessibilityTreeHelpers
  CLICK_EVENT_TYPES = %w[click mousedown mouseup].freeze
  # States announced even when false (e.g., "collapsed"); other false properties are defaults and left out of the tree.
  ANNOUNCED_FALSE_STATES = %i[expanded pressed checked selected].freeze
  TREE_NOISE = { roles: %w[InlineTextBox], properties: %i[url] }.freeze

  # @return [Hash] role, name, description, properties (e.g., expanded: false), and child roles of the first match
  def accessibility_node(selector)
    backend_node_id = backend_node_id(selector)
    nodes = cdp('Accessibility.getPartialAXTree', backendNodeId: backend_node_id, fetchRelatives: true)['nodes']
    node = nodes.find { |candidate| candidate['backendDOMNodeId'] == backend_node_id }
    {
      role: node.dig('role', 'value'),
      name: node.dig('name', 'value'),
      description: node.dig('description', 'value'),
      properties: node_properties(node),
      child_roles: nodes.select { |candidate| candidate['parentId'] == node['nodeId'] }
                        .map { |child| child.dig('role', 'value') }
    }
  end

  # @return [String] the accessibility subtree of the first match, one indented line per node,
  #   e.g., 'cell "Collection"' then '  link "Capstone" focusable', skipping nodes screen readers ignore
  def accessibility_tree(selector)
    nodes = cdp('Accessibility.getFullAXTree')['nodes']
    nodes_by_id = nodes.index_by { |node| node['nodeId'] }
    root = nodes.find { |node| node['backendDOMNodeId'] == backend_node_id(selector) }
    accessibility_tree_lines(root, nodes_by_id, 0).join("\n")
  end

  # @return [Array<String>] the element and its ancestors below <body> that listen for clicks, e.g., "th#id.class"
  def click_listener_elements(selector)
    object_id = evaluate_to_object_id("document.querySelector(#{selector.to_json})")
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

  # Traces listeners to the script that added them, e.g., event_listener_sources('document.documentElement').
  # @param expression [String] JavaScript evaluating to an element, document, or window
  # @return [Array<Hash>] each listener's type, the script's opening (often a library banner), and the source
  #   around where the listener was added
  def event_listener_sources(expression)
    cdp('Debugger.enable')
    cdp('DOMDebugger.getEventListeners', objectId: evaluate_to_object_id(expression))['listeners']
      .map { |listener| listener_source(listener) }
  end

  DESCRIBE_ELEMENT_JS = <<~JS
    function() {
      if (this === document.body) return null
      return [this.tagName.toLowerCase(), this.id && `#${this.id}`, ...[...this.classList].map((name) => `.${name}`)].join('')
    }
  JS

  private

  def listener_source(listener)
    script = cdp('Debugger.getScriptSource', scriptId: listener['scriptId'])['scriptSource']
    line = script.lines[listener['lineNumber']].to_s
    start = [listener['columnNumber'] - 200, 0].max
    { type: listener['type'], capture: listener['useCapture'], script_start: script[0, 200], source: line[start, 400] }
  end

  def accessibility_tree_lines(node, nodes_by_id, depth)
    children = Array(node['childIds']).filter_map { |child_id| nodes_by_id[child_id] }
    shown = !node['ignored'] && TREE_NOISE[:roles].exclude?(node.dig('role', 'value'))
    child_depth = shown ? depth + 1 : depth
    child_lines = children.flat_map { |child| accessibility_tree_lines(child, nodes_by_id, child_depth) }
    shown ? [tree_line(node, depth)] + child_lines : child_lines
  end

  def tree_line(node, depth)
    [('  ' * depth) + node.dig('role', 'value').to_s, node.dig('name', 'value').presence&.to_json, *tree_flags(node)]
      .compact.join(' ')
  end

  def tree_flags(node)
    node_properties(node).except(*TREE_NOISE[:properties]).filter_map do |name, value|
      next if [false, 'false'].include?(value) && ANNOUNCED_FALSE_STATES.exclude?(name)

      value == true ? name.to_s : "#{name}=#{value}"
    end
  end

  def node_properties(node)
    Array(node['properties']).to_h { |property| [property['name'].to_sym, property.dig('value', 'value')] }
  end

  def backend_node_id(selector)
    root_id = cdp('DOM.getDocument', depth: 0).dig('root', 'nodeId')
    node_id = cdp('DOM.querySelector', nodeId: root_id, selector:)['nodeId']
    cdp('DOM.describeNode', nodeId: node_id).dig('node', 'backendNodeId')
  end

  def evaluate_to_object_id(expression)
    cdp('Runtime.evaluate', expression:).dig('result', 'objectId')
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
