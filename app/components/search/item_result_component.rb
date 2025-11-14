# frozen_string_literal: true

module Search
  # Component to render a single item result in search results
  class ItemResultComponent < ViewComponent::Base
    with_collection_parameter :result

    # @param result [SearchResults::Item]
    def initialize(result:)
      @result = result
      super()
    end

    attr_reader :result

    delegate :title, :druid, :bare_druid, to: :result

    def id
      "item-result-#{bare_druid}"
    end

    def argo_path
      "#{Settings.argo.url}/view/#{bare_druid}"
    end
  end
end
