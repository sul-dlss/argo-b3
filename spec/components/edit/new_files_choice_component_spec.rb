# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::NewFilesChoiceComponent, type: :component do
  it 'renders the choice, appending by default, submitted with the item form' do
    render_inline(described_class.new)

    expect(page).to have_css('fieldset legend', text: 'New files have been added. How should they be structured?')
    expect(page).to have_field('Append files to structure', type: 'radio', checked: true)
    expect(page).to have_field('Rebuild structure', type: 'radio', checked: false)
    expect(page).to have_css('input[type="radio"][form="item_form"][name="new_files[structure]"]' \
                             '[data-new-files-choice-target="radio"]', count: 2)
    rebuild = page.find_field('Rebuild structure')
    expect(page).to have_css("##{rebuild['aria-describedby']}",
                             text: 'Replaces all existing resources, including any changes to labels, order, ' \
                                   'or file settings.')
  end
end
