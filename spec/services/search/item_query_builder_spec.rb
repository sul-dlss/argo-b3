# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::ItemQueryBuilder do
  subject(:item_query) { described_class.call(search_form:) }

  context 'with a blank search form' do
    let(:search_form) { Search::ItemForm.new(query: '') }

    it 'builds the correct query parts' do
      result = described_class.call(search_form:)
      expect(result).to include(fq: ['-governed_by_ssim:"druid:bf569gy6501"'], 'q.alt': '*:*', defType: 'dismax')
      expect(result).to have_key(:qf)
    end
  end

  context 'with a query' do
    let(:search_form) { Search::ItemForm.new(query: 'test') }

    it 'builds the correct query parts' do
      result = described_class.call(search_form:)
      expect(result).to include(q: 'test')
    end
  end

  context 'when debug is true' do
    let(:search_form) { Search::ItemForm.new(debug: true) }

    it 'includes debugQuery in the result' do
      result = described_class.call(search_form:)
      expect(result).to include(debugQuery: true)
    end
  end

  context 'with google books included' do
    let(:search_form) { Search::ItemForm.new(include_google_books: true) }

    it 'does not exclude google books from the filter queries' do
      result = described_class.call(search_form:)
      expect(Array(result[:fq])).not_to include('-governed_by_ssim:"druid:bf569gy6501"')
    end
  end

  context 'with object types' do
    let(:search_form) { Search::ItemForm.new(object_types: %w[dro collection]) }

    it 'builds the correct filter query for object types' do
      result = described_class.call(search_form:)
      expect(Array(result[:fq])).to include("{!tag=#{Search::Fields::OBJECT_TYPE}}#{Search::Fields::OBJECT_TYPE}:(\"dro\" OR \"collection\")") # rubocop:disable Layout/LineLength
    end
  end

  context 'with projects' do
    let(:search_form) { Search::ItemForm.new(projects: ['Project A', 'Project B']) }

    it 'builds the correct filter query for projects' do
      result = described_class.call(search_form:)
      expect(Array(result[:fq])).to include("#{Search::Fields::PROJECT_TAGS}:(\"Project A\" OR \"Project B\")")
    end
  end

  context 'with access rights' do
    let(:search_form) { Search::ItemForm.new(access_rights: ['dark']) }

    it 'builds the correct filter query for access rights' do
      result = described_class.call(search_form:)
      expect(Array(result[:fq])).to include("#{Search::Fields::ACCESS_RIGHTS}:(\"dark\")")
    end
  end

  context 'with tags' do
    let(:search_form) { Search::ItemForm.new(tags: ['Tag A', 'Tag B : Tag B1']) }

    it 'builds the correct filter query for tags' do
      result = described_class.call(search_form:)
      expect(Array(result[:fq])).to include("#{Search::Fields::OTHER_TAGS}:(\"Tag A\" OR \"Tag B : Tag B1\")")
    end
  end

  context 'with wps workflows' do
    let(:search_form) { Search::ItemForm.new(wps_workflows: ['ocrWF:end-ocr:waiting']) }

    it 'builds the correct filter query for wps workflows' do
      result = described_class.call(search_form:)
      expect(Array(result[:fq])).to include("#{Search::Fields::WPS_WORKFLOWS}:(\"ocrWF:end-ocr:waiting\")")
    end
  end

  context 'with mimetypes' do
    let(:search_form) { Search::ItemForm.new(mimetypes: ['application/pdf']) }

    it 'builds the correct filter query for mimetypes' do
      result = described_class.call(search_form:)
      expect(Array(result[:fq])).to include("#{Search::Fields::MIMETYPES}:(\"application/pdf\")")
    end
  end
end
