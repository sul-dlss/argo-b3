import { BaseRuleVisitor, ParserRule } from '@herb-tools/linter'
import { isERBNode } from '@herb-tools/core'

const MESSAGE = 'Build an element whose attributes take Ruby values with a tag helper (`tag.div`, `link_to`, etc.), ' +
  'passing the attributes as arguments and `data-*` attributes in a `data:` hash.'

class NoERBInAttributeValueVisitor extends BaseRuleVisitor {
  visitHTMLAttributeValueNode (node) {
    // Covers output tags and control flow (e.g., `class="<% if active %>active<% end %>"`).
    const erbNode = node.children.find(isERBNode)
    if (erbNode) this.addOffense(MESSAGE, erbNode.location)

    super.visitHTMLAttributeValueNode(node)
  }
}

export default class NoERBInAttributeValueRule extends ParserRule {
  static ruleName = 'argo-b3-no-erb-in-attribute-value'

  check (result, context) {
    const visitor = new NoERBInAttributeValueVisitor(this.ruleName, context)
    visitor.visit(result.value)
    return visitor.offenses
  }
}
