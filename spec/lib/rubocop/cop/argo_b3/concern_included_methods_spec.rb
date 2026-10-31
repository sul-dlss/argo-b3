# frozen_string_literal: true

require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../../lib/rubocop/cop/argo_b3/concern_included_methods'

RSpec.describe RuboCop::Cop::ArgoB3::ConcernIncludedMethods, :config do
  it 'registers an offense for a method defined inside included do' do
    expect_offense(<<~RUBY)
      module TitleConcern
        extend ActiveSupport::Concern

        included do
          validates :title, presence: true

          def title_present?
          ^^^^^^^^^^^^^^^^^^ Define concern methods in the module body, not inside `included do`.
            title.present?
          end
        end
      end
    RUBY
  end

  it 'registers an offense when the method is the only statement' do
    expect_offense(<<~RUBY)
      included do
        def title
        ^^^^^^^^^ Define concern methods in the module body, not inside `included do`.
          'Title'
        end
      end
    RUBY
  end

  it 'does not register an offense for methods in the module body' do
    expect_no_offenses(<<~RUBY)
      module TitleConcern
        extend ActiveSupport::Concern

        included do
          validates :title, presence: true
        end

        def title_present?
          title.present?
        end
      end
    RUBY
  end
end
