# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get '/webauth/login', to: 'authentication#login', as: 'login'
  get '/webauth/logout', to: 'authentication#logout', as: 'logout'
  get '/test_login/:id', to: 'authentication#test_login', as: 'test_login', param: :id if Rails.env.test?

  # Defines the root path route ("/")
  root 'search#show'

  # resource :home, only: [:show], controller: 'home'

  resource :search, only: [:show], controller: 'search' do
    scope module: :search do
      resources :items, only: [:index] do
        collection do
          get 'secondary_facets'
        end
      end

      resources :projects, only: [:index]

      resources :tags, only: [:index]

      resources :tickets, only: [:index]

      resources :tag_facets, only: [:index] do
        collection do
          get 'children'
          get 'search'
        end
      end

      resources :project_facets, only: [:index] do
        collection do
          get 'children'
          get 'search'
        end
      end

      resources :ticket_facets, only: [:index] do
        collection do
          get 'search'
        end
      end

      resources :collection_facets, only: [:index] do
        collection do
          get 'search'
        end
      end

      resources :admin_policy_facets, only: [:index] do
        collection do
          get 'search'
        end
      end

      resources :workflow_facets, only: [:index] do
        collection do
          get 'children'
        end
      end

      resources :mimetype_facets, only: [:index] do
        collection do
          get 'search'
        end
      end

      resources :date_facets, only: [:index] do
        collection do
          get 'search'
        end
      end

      resources :topic_facets, only: [:index] do
        collection do
          get 'search'
        end
      end

      resources :region_facets, only: [:index] do
        collection do
          get 'search'
        end
      end

      resources :genre_facets, only: [:index] do
        collection do
          get 'search'
        end
      end

      resources :language_facets, only: [:index] do
        collection do
          get 'search'
        end
      end
    end
  end

  resource :report, only: [:show], controller: 'reports' do
    collection do
      post 'download'
      post 'preview'
    end
  end

  resource :workflow_grid, only: %i[show], controller: 'workflow_grid' do
    post 'reset'
  end

  resources :bulk_actions, only: %i[new]

  namespace :bulk_actions do
    resource :reindex, only: %i[new create], controller: 'reindex'
  end

  namespace :admin do
    get 'groups'
  end
end
