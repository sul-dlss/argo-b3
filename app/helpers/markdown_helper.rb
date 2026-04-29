module MarkdownHelper
  def render_markdown(text)
    Commonmarker.to_html(
      text.to_s,
      options: {
        extension: {
          autolink: true,
          strikethrough: true,
          table: true,
          tagfilter: true
        }
      }
    ).html_safe
  end
end
