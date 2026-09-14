# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemsRegistrationForm do
  describe 'validation of item_registrations' do
    context 'when some item registrations are blank and some are not' do
      let(:form) do
        described_class.new(item_registrations_attributes: [{ title: 'A title' }, {}])
      end

      it 'discards the blank item registrations before validation' do
        form.valid?

        expect(form.item_registrations.map(&:title)).to eq(['A title'])
        expect(form.errors[:item_registrations]).to be_empty
      end
    end

    context 'when every item registration is blank' do
      let(:form) do
        described_class.new(item_registrations_attributes: [{}, {}])
      end

      it 'keeps the blank item registrations and reports a presence error' do
        form.valid?

        expect(form.item_registrations.size).to eq(2)
        expect(form.errors[:item_registrations]).to include('at least one item is required')
      end
    end

    context 'when at least one item registration is not blank' do
      let(:form) do
        described_class.new(item_registrations_attributes: [{ title: 'A title' }])
      end

      it 'does not report a presence error' do
        form.valid?

        expect(form.errors[:item_registrations]).to be_empty
      end
    end
  end

  describe '#invalid_item_registrations' do
    let(:form) do
      described_class.new(
        apo_druid: 'druid:bc123df4567',
        content_type: Cocina::Models::ObjectType.book,
        access_view: 'world',
        access_download: 'world',
        item_registrations_attributes: [
          { source_id: 'sul:1234', title: 'A title' },
          { source_id: 'sul:5678' }
        ]
      )
    end

    it 'returns only the item registrations with errors' do
      form.valid?

      expect(form.invalid_item_registrations.map(&:source_id)).to eq(['sul:5678'])
    end
  end

  describe 'tab-delimited items' do
    let(:items_choice) { described_class::ENTER_TAB_DELIMITED_CHOICE }

    context 'when every row has all of the columns' do
      let(:form) do
        described_class.new(
          items_choice:,
          tab_delimited_items: "36105212345678\tin11403803\tsul:first-item\tFirst title\n" \
                               "36105287654321\tin11403804\tsul:second-item\tSecond title"
        )
      end

      it 'builds an item registration per row' do
        form.valid?

        item_registrations = form.item_registrations.to_a
        expect(item_registrations.map(&:barcode)).to eq(%w[36105212345678 36105287654321])
        expect(item_registrations.map(&:catalog_record_id)).to eq(%w[in11403803 in11403804])
        expect(item_registrations.map(&:source_id)).to eq(['sul:first-item', 'sul:second-item'])
        expect(item_registrations.map(&:title)).to eq(['First title', 'Second title'])
      end
    end

    context 'when there are blank rows' do
      let(:form) do
        described_class.new(
          items_choice:,
          tab_delimited_items: "\n36105212345678\tin11403803\tsul:first-item\tFirst title\n " \
                               "\t \n" \
                               "36105287654321\tin11403804\tsul:second-item\tSecond title\n\n"
        )
      end

      it 'skips the blank rows' do
        form.valid?

        expect(form.item_registrations.map(&:source_id)).to eq(['sul:first-item', 'sul:second-item'])
      end
    end

    context 'when a row is missing trailing columns' do
      let(:form) do
        described_class.new(items_choice:, tab_delimited_items: "36105212345678\tin11403803")
      end

      it 'leaves the missing columns blank' do
        form.valid?

        item_registration = form.item_registrations.to_a.first
        expect(item_registration.barcode).to eq('36105212345678')
        expect(item_registration.catalog_record_id).to eq('in11403803')
        expect(item_registration.source_id).to be_blank
        expect(item_registration.title).to be_blank
      end
    end

    context 'when a row has extra columns' do
      let(:form) do
        described_class.new(
          items_choice:,
          tab_delimited_items: "36105212345678\tin11403803\tsul:first-item\tFirst title\tExtra"
        )
      end

      it 'ignores the extra columns' do
        form.valid?

        expect(form.item_registrations.to_a.first.title).to eq('First title')
      end
    end

    context 'when item registrations were also submitted' do
      let(:form) do
        described_class.new(
          items_choice:,
          tab_delimited_items: "36105212345678\tin11403803\tsul:first-item\tFirst title",
          item_registrations_attributes: [{ source_id: 'sul:ignored', title: 'Ignored title' }]
        )
      end

      it 'replaces them with the rows parsed from the tab-delimited items' do
        form.valid?

        expect(form.item_registrations.map(&:source_id)).to eq(['sul:first-item'])
      end
    end

    context 'when the tab-delimited items are blank' do
      let(:form) { described_class.new(items_choice:, tab_delimited_items: " \n ") }

      it 'reports the presence error for tab_delimited_items' do
        expect(form.valid?).to be false
        expect(form.errors[:tab_delimited_items]).to eq(['at least one item is required'])
        expect(form.errors[:item_registrations]).to be_empty
      end
    end

    context 'when the items choice is not the tab-delimited choice' do
      let(:form) do
        described_class.new(
          items_choice: described_class::ENTER_EACH_CHOICE,
          tab_delimited_items: "36105212345678\tin11403803\tsul:first-item\tFirst title",
          item_registrations_attributes: [{ source_id: 'sul:kept', title: 'Kept title' }]
        )
      end

      it 'ignores the tab-delimited items' do
        form.valid?

        expect(form.item_registrations.map(&:source_id)).to eq(['sul:kept'])
      end
    end
  end

  describe 'csv items' do
    let(:items_choice) { described_class::UPLOAD_CSV_CHOICE }

    context 'when every row has all of the columns' do
      let(:csv) do
        "barcode,folio_instance_hrid,source_id,title\n" \
          "36105212345678,in11403803,sul:first-item,First title\n" \
          "36105287654321,in11403804,sul:second-item,Second title\n"
      end
      let(:form) { described_class.new(items_choice:, csv:) }

      it 'builds an item registration per row' do
        form.valid?

        item_registrations = form.item_registrations.to_a
        expect(item_registrations.map(&:barcode)).to eq(%w[36105212345678 36105287654321])
        expect(item_registrations.map(&:catalog_record_id)).to eq(%w[in11403803 in11403804])
        expect(item_registrations.map(&:source_id)).to eq(['sul:first-item', 'sul:second-item'])
        expect(item_registrations.map(&:title)).to eq(['First title', 'Second title'])
        expect(form.errors[:csv_file]).to be_empty
      end
    end

    context 'when the columns are in a different order and there are extra columns' do
      let(:csv) { "title,extra,source_id\nFirst title,Ignored,sul:first-item\n" }
      let(:form) { described_class.new(items_choice:, csv:) }

      it 'maps the columns by header and ignores the extra columns' do
        form.valid?

        item_registration = form.item_registrations.to_a.first
        expect(item_registration.source_id).to eq('sul:first-item')
        expect(item_registration.title).to eq('First title')
        expect(item_registration.barcode).to be_blank
        expect(item_registration.catalog_record_id).to be_blank
      end
    end

    context 'when item registrations were also submitted' do
      let(:csv) { "source_id,title\nsul:first-item,First title\n" }
      let(:form) do
        described_class.new(items_choice:, csv:,
                            item_registrations_attributes: [{ source_id: 'sul:ignored', title: 'Ignored title' }])
      end

      it 'replaces them with the rows parsed from the csv' do
        form.valid?

        expect(form.item_registrations.map(&:source_id)).to eq(['sul:first-item'])
      end
    end

    context 'when the csv is missing the source_id column' do
      let(:csv) { "folio_instance_hrid,title\nin11403803,First title\n" }
      let(:form) { described_class.new(items_choice:, csv:) }

      it 'reports the error for csv_file' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(['missing headers: source_id.'])
        expect(form.errors[:csv]).to be_empty
        expect(form.errors[:item_registrations]).to be_empty
      end
    end

    context 'when the csv is blank' do
      let(:form) { described_class.new(items_choice:) }

      it 'reports the error for csv_file' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(["can't be blank"])
        expect(form.errors[:csv]).to be_empty
        expect(form.errors[:item_registrations]).to be_empty
      end
    end

    context 'when the csv has no rows' do
      let(:csv) { "barcode,folio_instance_hrid,source_id,title\n" }
      let(:form) { described_class.new(items_choice:, csv:) }

      it 'reports the presence error for csv_file' do
        expect(form.valid?).to be false
        expect(form.errors[:csv_file]).to eq(['at least one item is required'])
        expect(form.errors[:item_registrations]).to be_empty
      end
    end

    context 'when the items choice is not the upload csv choice' do
      let(:csv) { "source_id,title\nsul:ignored,Ignored title\n" }
      let(:form) do
        described_class.new(items_choice: described_class::ENTER_EACH_CHOICE, csv:,
                            item_registrations_attributes: [{ source_id: 'sul:kept', title: 'Kept title' }])
      end

      it 'ignores the csv' do
        form.valid?

        expect(form.item_registrations.map(&:source_id)).to eq(['sul:kept'])
        expect(form.errors[:csv_file]).to be_empty
      end
    end
  end
end
