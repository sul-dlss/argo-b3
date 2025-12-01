# frozen_string_literal: true

# Controller for the home page
class HomeController < SearchApplicationController
  def show
    @search_form = build_form(form_class: Search::Form)
    @items_search_form = build_form(form_class: Search::ItemForm)

    return if @search_form.query.blank?

    @projects_search_form = build_form(form_class: Search::Form)
    @tags_search_form = build_form(form_class: Search::Form)
    @tickets_search_form = build_form(form_class: Search::Form)
  end
end
