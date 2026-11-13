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
  root 'dashboard#index'
  post 'go_to_druid', to: 'dashboard#go_to_druid'

  # resource :home, only: [:show], controller: 'home'

  # Facet and field-value endpoints are shared by every search view. They are mounted under each
  # view's route so that the route (not a user-supplied param) determines which search form class
  # the controller builds -- see SearchFormConcern.
  concern :search_endpoints do
    scope module: :search do
      resources :items, only: [:index] do
        collection do
          get 'secondary_facets'
        end
      end

      resources :projects, only: [:index]

      resources :tags, only: [:index]

      resources :tickets, only: [:index]

      # One resource per routed facet, keeping its *_facets path helpers; the default tells the controller which facet.
      Search::Facets::ROUTED.each do |facet_config|
        resources facet_config.facet_resource, only: facet_config.facet_index ? [:index] : [], controller: 'facets',
                                               defaults: { facet_form_field: facet_config.form_field.to_s } do
          collection do
            get 'children' if facet_config.facet_children
            get 'search' if facet_config.facet_search
          end
        end
      end
    end
  end

  # Every route that builds a search form declares which view it belongs to via the view_form
  # default. Route defaults take precedence over query params, so the view cannot be spoofed.
  scope defaults: { view_form: 'results' } do
    resource :search, only: [:show], controller: 'search' do
      concerns :search_endpoints
    end
  end

  scope defaults: { view_form: 'advanced' } do
    get 'advanced_search', to: 'search#advanced', as: :advanced_search
    resource :advanced_search, only: [] do
      concerns :search_endpoints
    end
  end

  scope defaults: { view_form: 'workflow_grid' } do
    resource :workflow_grid, only: %i[show], controller: 'workflow_grid' do
      concerns :search_endpoints
      post 'reset'
    end
  end

  # Routes a search form to its view. Each form class maps to its own route, so components can call
  # url_for(form) without knowing which view they are rendering in.
  # Note that the mapping is keyed by model_name, which Blanks derives by stripping the "Form"
  # suffix, so these are named via model_name rather than spelled out.
  resolve(ResultsSearchForm.model_name.name) { |form, options| [:search, form.attributes.merge(options)] }
  resolve(AdvancedSearchForm.model_name.name) { |form, options| [:advanced_search, form.attributes.merge(options)] }
  resolve(WorkflowGridSearchForm.model_name.name) do |form, options|
    [:workflow_grid, form.attributes.merge(options)]
  end

  resource :report, only: [:show], controller: 'reports' do
    collection do
      post 'download'
      post 'preview'
    end
  end

  resources :bulk_actions, only: %i[new index show destroy] do
    member do
      get 'file'
      post 'cancel'
    end
  end

  namespace :bulk_actions do
    BulkActions.all.select(&:routable?).each do |config|
      resource config.key, only: %i[new create], controller: config.controller,
                           defaults: { bulk_action_type: config.key }
    end
  end

  # Redirect legacy route for object show page
  get '/view/:druid', to: redirect('/objects/%{druid}')

  resources :objects, only: %i[show], param: :druid do
    member do
      get 'track', to: 'objects#track'
      get 'overview', to: 'objects#show_overview'
      get 'json', to: 'objects#show_json'
      get 'workflows', to: 'objects#show_workflows'
      get 'versions', to: 'objects#show_versions'
      get 'events', to: 'objects#show_events'
      get 'releases', to: 'objects#show_releases'
      get 'purl_preview', to: 'objects#show_purl_preview'
      get 'solr_doc', to: 'objects#show_solr_doc'
      get 'files', to: 'objects#show_files'
      get 'structure', to: 'objects#show_structure'
      get 'constituents', to: 'objects#show_constituents'
      post 'republish', to: 'objects#republish'
      post 'deposit', to: 'objects#deposit'
      delete 'discard_draft', to: 'objects#discard_draft'
      delete 'purge', to: 'objects#purge'
      get 'structural_csv', to: 'objects#show_structural_csv'
      get 'descriptive_csv', to: 'objects#show_descriptive_csv'
      get 'virtual_object_csv', to: 'objects#show_virtual_object_csv'
    end
    resource :technical_metadata, only: %i[show], controller: 'technical_metadata'
    resource :file_download, only: %i[show]
    resources :user_versions, only: [], param: :user_version do
      member do
        post 'withdraw'
        post 'restore'
      end
    end
    resources :versions, only: [], param: :version, controller: 'object_versions' do
      member do
        get 'cocina'
        get 'structural_csv'
        get 'descriptive_csv'
      end
    end
  end
  scope 'objects/:druid', as: :object do
    resource :tags, only: %i[edit update], controller: 'administrative_tags'
    patch 'workflows/:workflow_name/processes/:process', to: 'workflow_processes#update', as: :workflow_process
  end

  resources :items, only: %i[new create edit update]
  scope 'items/:druid', as: :item do
    resources :releases, only: %i[new create], controller: 'item_releases'
  end

  resources :apos, only: %i[new create edit update]
  resources :agreements, only: %i[new create edit update]
  resources :collections, only: %i[new create edit update]

  resources :multiple_items, only: %i[new create show]

  resources :multi_item_deposit_actions, only: %i[index create show edit update] do
    get 'structural_metadata_csv_template', on: :member
    get 'discovery_report', on: :member
    get 'structure_report', on: :member
    resource :globus, only: %i[new create], controller: 'multi_item_deposit_globus'
  end

  resources :contents, only: %i[edit show update] do
    resource :dropzone, only: %i[update], controller: 'content_dropzone'
    resource :mount, only: %i[new create], controller: 'content_mount'
    resource :globus, only: %i[new create], controller: 'content_globus' do
      post 'discover'
    end
    resource :structure, only: %i[destroy], controller: 'content_structure' do
      get 'csv'
      get 'validation'
    end

    resources :content_file_sets, only: %i[edit update show destroy] do
      patch :move, on: :member
    end
    resources :content_file_binaries, only: %i[destroy]
    resource :unsaved_changes, only: %i[destroy], controller: 'content_unsaved_changes'
  end

  resources :collection_options, only: %i[index], defaults: { format: :json }

  resources :catalog_titles, only: %i[index], defaults: { format: :json }

  resources :apo_defaults, only: %i[show], param: :druid, defaults: { format: :json }

  resources :tag_suggestions, only: %i[index], defaults: { format: :json }

  resources :pinned_objects, only: %i[create destroy]

  resources :pinned_searches, only: %i[create destroy]

  resources :pinned_tags, only: %i[create destroy]

  namespace :admin do
    get 'impersonate', to: 'impersonation#edit'
    patch 'impersonate', to: 'impersonation#update'
    delete 'impersonate', to: 'impersonation#destroy', as: :stop_impersonate
    resources :workgroup_permissions, only: %i[index edit update], param: :workgroup
    resources :permissions, only: %i[destroy], controller: 'workgroup_permissions'
    resources :objects, only: [], param: :druid do
      resources :permissions, only: %i[index create destroy], controller: 'object_permissions'
    end
  end

  mount MissionControl::Jobs::Engine, at: '/jobs'

  if Rails.env.development?
    mount SdrViewComponents::Engine => '/sdr_view_components'
    mount Lookbook::Engine, at: '/lookbook'
  end
end
