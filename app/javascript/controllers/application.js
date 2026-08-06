import { Application } from '@hotwired/stimulus'
import TabErrorController from 'sdr_view_components/tab_error_controller'
import TabLinkController from 'sdr_view_components/tab_link_controller'
import TabNavController from 'sdr_view_components/tab_nav_controller'

const application = Application.start()
application.register('sdr-tab-error', TabErrorController)
application.register('sdr-tab-link', TabLinkController)
application.register('sdr-tab-nav', TabNavController)

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }
