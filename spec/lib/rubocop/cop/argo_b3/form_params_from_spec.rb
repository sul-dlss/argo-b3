# frozen_string_literal: true

require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../../lib/rubocop/cop/argo_b3/form_params_from'

RSpec.describe RuboCop::Cop::ArgoB3::FormParamsFrom, :config do
  it 'registers an offense when permitted_params is used to read params' do
    expect_offense(<<~RUBY)
      params.permit(item: NewItemForm.permitted_params)[:item]
                                      ^^^^^^^^^^^^^^^^ Read form params with `Form.params_from(params)` rather than `permitted_params`.
    RUBY
  end

  it 'registers an offense when permitted_params is passed to expect' do
    expect_offense(<<~RUBY)
      params.expect(form_class.model_name.param_key => form_class.permitted_params)
                                                                  ^^^^^^^^^^^^^^^^ Read form params with `Form.params_from(params)` rather than `permitted_params`.
    RUBY
  end

  it 'does not register an offense for params_from' do
    expect_no_offenses(<<~RUBY)
      NewItemForm.params_from(params)
    RUBY
  end
end
