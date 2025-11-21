# frozen_string_literal: true

Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root 'home#show'

  resource :home, only: [:show], controller: 'home'

  namespace :search do
    resources :items, only: [:index]

    resources :projects, only: [:index]

    resources :tags, only: [:index]

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

    resources :workflow_facets, only: [:index] do
      collection do
        get 'children'
      end
    end

    resources :mimetype_facets, only: [:index] do
      collection do
        get 'children'
        get 'search'
      end
    end
  end
end
