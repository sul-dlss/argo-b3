# frozen_string_literal: true

class UrlFetchTool < RubyLLM::Tool
  description 'Fetches the contents of a URL using HTTP GET.'

  params do
    string :url, description: 'The URL to fetch.'
  end

  def execute(url:)
    raise ArgumentError, 'Invalid URL' unless url&.match?(URI::DEFAULT_PARSER.make_regexp)

    response = Faraday.get(url)
    { url:, status: response.status, body: response.body }
  rescue StandardError => e
    { url:, error: e.message }
  end
end
