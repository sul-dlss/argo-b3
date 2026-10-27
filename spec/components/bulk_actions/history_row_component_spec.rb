# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActions::HistoryRowComponent, type: :component do
  include ActionView::RecordIdentifier

  let(:component) { described_class.new(bulk_action:, admin: false) }
  let(:user) { bulk_action.user }

  before do
    allow(Current).to receive(:user).and_return(user)
  end

  # Rendered within a table since rows outside of a table are dropped when parsed.
  def render_row
    render_in_view_context(component) { |row_component| tag.table(tag.tbody(render(row_component))) }
  end

  context 'when processing' do
    let(:bulk_action) do
      create(:bulk_action, action_type: :reindex, description: 'Test description',
                           created_at: Time.zone.parse('2026-04-16T10:00:00Z'))
    end

    it 'renders the row without downloads or delete' do
      render_row

      row = page.find("tr##{dom_id(bulk_action, 'row')}")
      expect(row).to have_css('td', count: 7)
      expect(row).to have_css("td:nth-of-type(1) a[href='/bulk_actions/#{bulk_action.id}']",
                              text: "Bulk action #{bulk_action.id}: Test description")
      expect(row).to have_css('td:nth-of-type(2)', text: 'Reindex')
      expect(row).to have_css('td:nth-of-type(3)', text: '2026-04-16 03:00:00 PT')
      expect(row).to have_css('td:nth-of-type(4)', text: 'Processing')
      expect(row).to have_no_css('td:nth-of-type(4) i.bi')
      expect(row).to have_css('td:nth-of-type(5)', text: '0 / 0 / 0')
      expect(row).to have_no_css('td:nth-of-type(6) a')
      expect(row).to have_no_css('td:nth-of-type(7) form')
      expect(row).to have_no_button('Cancel')
    end
  end

  context 'when completed with files' do
    let(:bulk_action) do
      create(:bulk_action, :with_log, :with_export,
             action_type: :export_cocina_json,
             status: :completed,
             druid_count_success: 5, druid_count_fail: 2, druid_count_total: 7)
    end

    it 'renders the row with downloads and delete' do
      render_row

      row = page.find("tr##{dom_id(bulk_action, 'row')}")
      expect(row).to have_css("td:nth-of-type(1) a[href='/bulk_actions/#{bulk_action.id}']",
                              exact_text: "Bulk action #{bulk_action.id}")
      expect(row).to have_css('td:nth-of-type(2)', text: 'Download full Cocina JSON')
      expect(row).to have_css('td:nth-of-type(4)', text: 'Completed')
      expect(row).to have_css('td:nth-of-type(4) i.bi-exclamation-triangle-fill.text-warning')
      expect(row).to have_css('td:nth-of-type(5)', text: '7 / 5 / 2')
      expect(row).to have_css('td:nth-of-type(6) ul > li', count: 2)
      expect(row).to have_css('td:nth-of-type(6) a', text: 'Log')
      expect(row).to have_link('Cocina JSON')
      expect(row).to have_css(
        "td:nth-of-type(7) form[action='/bulk_actions/#{bulk_action.id}']" \
        "[data-turbo-confirm='Delete this bulk action from history? Its log and export files will also be deleted. " \
        "This cannot be undone.'] button.btn-sm i.bi-trash"
      )
      expect(row).to have_button('Clear')
    end
  end

  context 'when cancelled' do
    let(:bulk_action) { create(:bulk_action, action_type: :reindex, status: :cancelled) }

    it 'renders the clear button' do
      render_row

      row = page.find("tr##{dom_id(bulk_action, 'row')}")
      expect(row).to have_css('td:nth-of-type(4)', text: 'Cancelled')
      expect(row).to have_css("td:nth-of-type(7) form[action='/bulk_actions/#{bulk_action.id}'] button.btn-sm",
                              text: 'Clear')
    end
  end

  context 'when a bulk action has multiple export files' do
    let(:bulk_action) { create(:bulk_action, :with_export, action_type: :register_csv, status: :completed) }

    before do
      File.write(bulk_action.export_filepath(:tracking_sheets), 'PDF content')
    end

    it 'renders a link for each export file' do
      render_row

      row = page.find("tr##{dom_id(bulk_action, 'row')}")
      expect(row).to have_css('td:nth-of-type(6) ul > li', count: 2)
      expect(row).to have_css('td:nth-of-type(6) a', count: 2)
      expect(row).to have_link('Registration report',
                               href: "/bulk_actions/#{bulk_action.id}/file?filename=registration_report.csv")
      expect(row).to have_link('Tracking sheets',
                               href: "/bulk_actions/#{bulk_action.id}/file?filename=tracking_sheets.pdf")
    end
  end

  context 'when an admin' do
    let(:component) { described_class.new(bulk_action:, admin: true) }
    let(:user) { create(:user, :admin) }
    let(:bulk_action) do
      create(:bulk_action, action_type: :reindex, user: create(:user, email_address: 'mmouse@stanford.edu'))
    end

    it 'renders the user after the bulk action name' do
      render_row

      row = page.find("tr##{dom_id(bulk_action, 'row')}")
      expect(row).to have_css('td', count: 8)
      expect(row).to have_css('td:nth-of-type(2)', text: 'mmouse')
      expect(row).to have_css('td:nth-of-type(3)', text: 'Reindex')
    end
  end

  describe 'cancel button' do
    let(:bulk_action) { create(:bulk_action, action_type: :reindex, status:) }
    let(:status) { :started }

    context 'when an admin and the bulk action is cancellable' do
      let(:user) { create(:user, :admin) }

      it 'renders the cancel button' do
        render_row

        row = page.find("tr##{dom_id(bulk_action, 'row')}")
        expect(row).to have_css("td:nth-of-type(7) form[action='/bulk_actions/#{bulk_action.id}/cancel'] " \
                                'button.btn-sm i.bi-x-square')
        expect(row).to have_css("form[action='/bulk_actions/#{bulk_action.id}/cancel'][method='post']" \
                                "[data-turbo-confirm='Cancel this bulk action? Changes already made to objects " \
                                "will not be undone.']")
        expect(row).to have_button('Cancel')
      end
    end

    context 'when an admin and the bulk action is not cancellable' do
      let(:user) { create(:user, :admin) }
      let(:status) { :completed }

      it 'does not render the cancel button' do
        render_row

        expect(page).to have_button('Clear')
        expect(page).to have_no_button('Cancel')
      end
    end

    context 'when not allowed to cancel' do
      it 'does not render the cancel button' do
        render_row

        expect(page).to have_css("tr##{dom_id(bulk_action, 'row')}")
        expect(page).to have_no_button('Cancel')
      end
    end
  end
end
