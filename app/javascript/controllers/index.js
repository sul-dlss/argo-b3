// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from 'controllers/application'
import { eagerLoadControllersFrom } from '@hotwired/stimulus-loading'
import { Autocomplete } from 'stimulus-autocomplete'
import ToastController from 'sdr_view_components/toast_controller'

eagerLoadControllersFrom('controllers', application)
application.register('autocomplete', Autocomplete)
application.register('sdr-toast', ToastController)
