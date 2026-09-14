# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TagsFormConcern do
  # ItemForm is used as a representative form that includes the concern.
  subject(:item_form) do
    ItemForm.new(
      source_id: 'new:source-id',
      title: 'The Title',
      apo_druid: 'druid:bc123df4567',
      content_type: Cocina::Models::ObjectType.object,
      access_view: 'world',
      access_download: 'world'
    )
  end

  before do
    allow(Sdr::Repository).to receive(:source_id_exists?).and_return(false)
  end

  describe 'other_tags' do
    context 'when valid' do
      before do
        item_form.other_tags_attributes = [{ tag: 'Registered By : mjgiarlo' }, { tag: 'Project : Argo' }]
      end

      it 'is valid and populates tags' do
        expect(item_form).to be_valid
        expect(item_form.tags).to eq(['Registered By : mjgiarlo', 'Project : Argo'])
      end
    end

    context 'when there are no other tags' do
      it 'populates tags with an empty array' do
        expect(item_form).to be_valid
        expect(item_form.tags).to eq([])
      end
    end

    context 'when some other tags are blank' do
      before do
        item_form.other_tags_attributes = [{ tag: 'Registered By : mjgiarlo' }, { tag: '' }, { tag: nil }]
      end

      it 'omits the blank tags' do
        expect(item_form).to be_valid
        expect(item_form.tags).to eq(['Registered By : mjgiarlo'])
      end
    end

    context 'when other tags are duplicated' do
      before do
        item_form.other_tags_attributes = [{ tag: 'Registered By : mjgiarlo' },
                                           { tag: 'Registered By : mjgiarlo' }]
      end

      it 'deduplicates the tags' do
        expect(item_form).to be_valid
        expect(item_form.tags).to eq(['Registered By : mjgiarlo'])
      end
    end

    context 'when invalid' do
      before do
        item_form.other_tags_attributes = [{ tag: 'Registered By' }]
      end

      it 'is not valid' do
        expect(item_form).not_to be_valid
        expect(item_form.other_tags.first.errors[:tag])
          .to include('must be a series of 2 or more strings delimited with space-padded colons')
      end
    end
  end

  describe 'project_tags' do
    context 'when present' do
      before do
        item_form.project_tags_attributes = [{ tag: 'Argo' }, { tag: 'Google Books' }]
      end

      it 'populates tags with the "Project : " prefix' do
        expect(item_form).to be_valid
        expect(item_form.tags).to eq(['Project : Argo', 'Project : Google Books'])
      end
    end

    context 'when the tag includes the "Project : " prefix' do
      before do
        item_form.project_tags_attributes = [{ tag: 'Project : Argo' }]
      end

      it 'does not duplicate the prefix' do
        expect(item_form).to be_valid
        expect(item_form.tags).to eq(['Project : Argo'])
      end
    end

    context 'when some project tags are blank' do
      before do
        item_form.project_tags_attributes = [{ tag: 'Argo' }, { tag: '' }, { tag: nil }]
      end

      it 'omits the blank tags' do
        expect(item_form).to be_valid
        expect(item_form.tags).to eq(['Project : Argo'])
      end
    end

    context 'when project tags are duplicated' do
      before do
        item_form.project_tags_attributes = [{ tag: 'Argo' }, { tag: 'Argo' }]
      end

      it 'deduplicates the tags' do
        expect(item_form).to be_valid
        expect(item_form.tags).to eq(['Project : Argo'])
      end
    end
  end

  describe 'ticket_tags' do
    context 'when present' do
      before do
        item_form.ticket_tags_attributes = [{ tag: 'ABC-123' }, { tag: 'ABC-456' }]
      end

      it 'populates tags with the "Ticket : " prefix' do
        expect(item_form).to be_valid
        expect(item_form.tags).to eq(['Ticket : ABC-123', 'Ticket : ABC-456'])
      end
    end

    context 'when the tag includes the "Ticket : " prefix' do
      before do
        item_form.ticket_tags_attributes = [{ tag: 'Ticket : ABC-123' }]
      end

      it 'does not duplicate the prefix' do
        expect(item_form).to be_valid
        expect(item_form.tags).to eq(['Ticket : ABC-123'])
      end
    end

    context 'when some ticket tags are blank' do
      before do
        item_form.ticket_tags_attributes = [{ tag: 'ABC-123' }, { tag: '' }, { tag: nil }]
      end

      it 'omits the blank tags' do
        expect(item_form).to be_valid
        expect(item_form.tags).to eq(['Ticket : ABC-123'])
      end
    end

    context 'when ticket tags are duplicated' do
      before do
        item_form.ticket_tags_attributes = [{ tag: 'ABC-123' }, { tag: 'ABC-123' }]
      end

      it 'deduplicates the tags' do
        expect(item_form).to be_valid
        expect(item_form.tags).to eq(['Ticket : ABC-123'])
      end
    end
  end

  describe 'populate_tags' do
    before do
      item_form.other_tags_attributes = [{ tag: 'Registered By : mjgiarlo' }]
      item_form.project_tags_attributes = [{ tag: 'Argo' }]
      item_form.ticket_tags_attributes = [{ tag: 'ABC-123' }]
    end

    it 'populates tags with other, project, and ticket tags' do
      expect(item_form).to be_valid
      expect(item_form.tags).to eq(['Registered By : mjgiarlo', 'Project : Argo', 'Ticket : ABC-123'])
    end
  end

  describe '.permitted_params' do
    it 'includes nested other_tags_attributes' do
      expect(ItemForm.permitted_params).to include(
        other_tags_attributes: OtherTagForm.permitted_params
      )
    end

    it 'includes nested project_tags_attributes' do
      expect(ItemForm.permitted_params).to include(
        project_tags_attributes: ProjectTagForm.permitted_params
      )
    end

    it 'includes nested ticket_tags_attributes' do
      expect(ItemForm.permitted_params).to include(
        ticket_tags_attributes: TicketTagForm.permitted_params
      )
    end
  end
end
