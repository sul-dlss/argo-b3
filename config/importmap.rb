# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application'
pin '@hotwired/turbo-rails', to: 'turbo.min.js'
pin '@hotwired/stimulus', to: 'stimulus.min.js'
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js'
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin '@popperjs/core', to: 'https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8'
pin 'bootstrap', to: 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/+esm'
pin 'stimulus-autocomplete' # @3.1.0
pin '@andypf/json-viewer', to: '@andypf--json-viewer.js' # @2.4.0
pin 'sdr_view_components/toast_controller', to: 'sdr_view_components/toast_controller.js'
pin 'sdr_view_components/tab_select_controller', to: 'sdr_view_components/tab_select_controller.js'
pin 'sdr_view_components/tab_error_controller', to: 'sdr_view_components/tab_error_controller.js'
pin 'sdr_view_components/tab_link_controller', to: 'sdr_view_components/tab_link_controller.js'
pin 'sdr_view_components/tab_nav_controller', to: 'sdr_view_components/tab_nav_controller.js'
pin 'dropzone' # @6.0.0
pin 'just-extend' # @5.1.1 (dropzone dependency)
