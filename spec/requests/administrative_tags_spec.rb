# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Administrative tags' do
  let(:user) { create(:user, :reader) }
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid, title: 'My item') }
  let(:current_tags) { ['Registered By : jdoe', 'Project : Maps', 'Ticket : DIGREQ-1'] }

  before do
    allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
    allow(Sdr::AdministrativeTags).to receive(:list).and_return(current_tags)
    allow(Sdr::AdministrativeTags).to receive(:replace)
    sign_in(user)
  end

  describe 'edit' do
    context 'when the user can edit the object' do
      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'renders the form with the current tags' do
        get "/objects/#{druid}/tags/edit"

        expect(response).to have_http_status(:ok)
        expect(Sdr::Repository).to have_received(:find).with(druid:, without_structural_contains: true)
        expect(Sdr::AdministrativeTags).to have_received(:list).with(druid:)
        page = Capybara.string(response.body)
        expect(page).to have_css('h1', text: 'Manage tags')
        expect(page).to have_text('My item')
        expect(page).to have_field('administrative_tags[other_tags_attributes][0][tag]', with: 'Registered By : jdoe')
        expect(page).to have_field('administrative_tags[project_tags_attributes][0][tag]', with: 'Maps')
        expect(page).to have_field('administrative_tags[ticket_tags_attributes][0][tag]', with: 'DIGREQ-1')
        expect(page).to have_link('Cancel', href: "/objects/#{druid}")
      end
    end

    context 'when the user cannot edit the object' do
      it 'redirects to the root' do
        get "/objects/#{druid}/tags/edit"

        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq(I18n.t('errors.not_authorized'))
      end
    end
  end

  describe 'update' do
    let(:tag_params) do
      { other_tags_attributes: { '0' => { tag: 'Registered By : jdoe' } },
        project_tags_attributes: { '0' => { tag: 'Maps' }, '1' => { tag: 'Atlases' } } }
    end

    context 'when the user can edit the object' do
      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        allow(Rails.cache).to receive(:delete).and_call_original
      end

      it 'replaces the tags and redirects with a toast' do
        patch "/objects/#{druid}/tags", params: { administrative_tags: tag_params }

        expect(Sdr::AdministrativeTags).to have_received(:replace)
          .with(druid:, tags: ['Registered By : jdoe', 'Project : Maps', 'Project : Atlases'])
        expect(Rails.cache).to have_received(:delete).with("objects/solr-doc/#{druid}")
        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('Tags updated')
      end

      context 'when the tags are unchanged' do
        let(:tag_params) do
          { other_tags_attributes: { '0' => { tag: 'Registered By : jdoe' } },
            project_tags_attributes: { '0' => { tag: 'Maps' } },
            ticket_tags_attributes: { '0' => { tag: 'DIGREQ-1' } } }
        end

        it 'does not replace the tags or toast' do
          patch "/objects/#{druid}/tags", params: { administrative_tags: tag_params }

          expect(Sdr::AdministrativeTags).not_to have_received(:replace)
          expect(response).to redirect_to(object_path(druid))
          expect(flash[:toast]).to be_nil
        end
      end

      context 'when a tag is invalid' do
        let(:tag_params) { { other_tags_attributes: { '0' => { tag: 'not a tag' } } } }

        it 'renders the form with an error' do
          patch "/objects/#{druid}/tags", params: { administrative_tags: tag_params }

          expect(response).to have_http_status(:unprocessable_content)
          expect(Sdr::AdministrativeTags).not_to have_received(:replace)
          expect(response.body).to include('must be a series of 2 or more strings delimited with space-padded colons')
        end
      end

      context 'when saving fails' do
        before do
          allow(Sdr::AdministrativeTags).to receive(:replace).and_raise(Sdr::AdministrativeTags::Error)
        end

        it 'renders the form with an error' do
          patch "/objects/#{druid}/tags", params: { administrative_tags: tag_params }

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include('The tags could not be saved.')
        end
      end
    end

    context 'when the user cannot edit the object' do
      it 'redirects to the root' do
        patch "/objects/#{druid}/tags", params: { administrative_tags: tag_params }

        expect(Sdr::AdministrativeTags).not_to have_received(:replace)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
