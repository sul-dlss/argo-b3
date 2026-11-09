# frozen_string_literal: true

# Returns the headings in an HTML fragment as [level, text] pairs, in DOM order.
def heading_outline(html)
  Nokogiri::HTML5.fragment(html).css('h1, h2, h3, h4, h5, h6, [role="heading"]').map do |heading|
    level = heading['aria-level']&.to_i || heading.name.delete_prefix('h').to_i
    [level, heading.text.squish]
  end
end
