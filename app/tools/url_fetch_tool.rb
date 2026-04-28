# frozen_string_literal: true

class UrlFetchTool < RubyLLM::Tool
  description 'Fetches the contents of a URL using HTTP GET.'

  params do
    string :url, description: 'The URL to fetch.'
  end

  def execute(url:)
    response = Faraday.get(url)
    { status: response.status, body: response.body }
  rescue Faraday::Error => e
    { error: e.message }
  end
end
