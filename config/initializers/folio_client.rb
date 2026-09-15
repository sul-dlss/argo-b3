# frozen_string_literal: true

# Configure folio_client singleton
FolioClient.configure(
  url: Settings.folio.okapi.url,
  login_params: {
    username: Settings.folio.okapi.username,
    password: Settings.folio.okapi.password
  },
  tenant_id: Settings.folio.tenant_id,
  user_agent: "folio_client #{FolioClient::VERSION}; argo #{Rails.env}"
)
