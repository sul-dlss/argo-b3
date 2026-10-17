# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermittedParamsConcern do
  describe '.params_from' do
    subject(:form_params) { ContentFileSetForm.params_from(ActionController::Parameters.new(params)) }

    context 'when the form params are submitted' do
      let(:params) do
        {
          content_file_set: {
            label: 'Page 1',
            not_an_attribute: 'dropped',
            content_files_attributes: { '0' => { id: '7', use: 'transcription' } }
          }
        }
      end

      it 'returns the permitted params under the param key, keeping nested attributes' do
        expect(form_params.to_h).to eq(
          'label' => 'Page 1',
          'content_files_attributes' => { '0' => { 'id' => '7', 'use' => 'transcription' } }
        )
      end
    end

    context 'when the form params are absent' do
      let(:params) { { other: 'value' } }

      it 'returns empty params' do
        expect(form_params.to_h).to eq({})
      end
    end
  end
end
