# How H3 sends email notifications (research for #1372)

Question: how does H3 send email notifications, and what of it should Argo-B3 copy?

**Which repo is H3.** H3 is `sul-dlss/hungry-hungry-hippo` ("H3 is a Rails web application enabling users to deposit scholarly content into SDR"). `sul-dlss/happy-heron` is **H2**, its predecessor (its README, `h2-administrators` list, and "An H2 version mismatch" subject). This note covers H3 and mentions H2 only where it differs in ways worth knowing (notably per-user opt-out).

Sources read (all primary):

- H3: `hungry-hungry-hippo` `origin/main` @ `a4582754` (2026-11-10). Paths below are relative to that repo unless prefixed.
- H2: `happy-heron` @ `b53ffbf0`.
- H3 deployed settings: `shared_configs` branches `origin/sul-h3-{prod,stage,qa}` @ `e1187c89` (`config/settings/production.yml`).
- Host mail relay: `puppet` @ `c46684fb29`.
- Rails defaults: `actionmailer-8.1.4` gem source.
- Argo-B3: this repo's `config/deploy*.yml`, `config/environments/*`, `app/mailers`.

## Summary

- H3 uses plain Action Mailer. Domain code publishes `ActiveSupport::Notifications` events through a small `Notifier`; subscriber blocks and "subscription mailer" classes choose recipients and call `deliver_later`. A single `Settings.notifications.enabled` flag gates every event-driven email.
- In production H3 does **not** configure a delivery method or SMTP settings. Rails then defaults to `:smtp` on `localhost:25` with no auth, and every H3 VM runs a Puppet-managed Postfix null client that relays to `smtp.stanford.edu`.
- Recipients are `User#email_address`. That is the Shibboleth `REMOTE_USER` (sunetid@stanford.edu), upserted at login. Admin notices go to `h2-administrators@lists.stanford.edu`.
- H3 has no per-user preferences or opt-out. A collection has two booleans that suppress participant-change emails. (H2 had per-user, per-collection `MailPreference` opt-outs, which H3 dropped.)
- Tests: rspec mailer specs with custom body matchers, `ActionMailer::TestHelper` enqueue assertions for the subscribers, and Action Mailer previews in `spec/mailers/previews`. Dev uses the `:file` delivery method. There is no `letter_opener`.
- For Argo-B3 under Kamal: the containers can't reach the host's loopback-only Postfix. Puppet would need to open it to the Docker bridge, which already has a precedent. The app would then point `smtp_settings` at `host.docker.internal:25` and set `default_url_options` and `from`. Details are under "Adopting the same delivery setup in Argo-B3".

## Mailers, templates, layout, footer

- Mailers (`app/mailers/`): `ApplicationMailer`, `WorksMailer`, `ReviewsMailer`, `CollectionsMailer`, `TermsMailer`, `ContactsMailer`, `WorkReportsMailer`, `CollectionReportsMailer`.
- `ApplicationMailer` sets `default from: 'no-reply@sdr.stanford.edu'` and `layout 'mailer'`. It also provides `set_work` (`@work`, with `@user = params[:user] || @work.user`, and `@collection`) and `set_work_presenter`, which fetches cocina and version status from SDR at render time to build a `WorkPresenter` (`app/mailers/application_mailer.rb`). Rendering an email can therefore make network calls to DSA.
- Mailers use the parameterized `Mailer.with(...).method` style. Some guard clauses inside the action return without calling `mail`, which suppresses the email. For example, `CollectionsMailer#invitation_to_deposit_email` returns unless `@collection.email_depositors_status_changed` (`app/mailers/collections_mailer.rb`).
- Templates are **HTML only** (`app/views/*_mailer/*.html.erb`). The one exception is the contact form's `contacts_mailer/jira_email.text.erb`. `layouts/mailer.text.erb` is just `<%= yield %>`, so the HTML emails have no plain-text part.
- Layout (`app/views/layouts/mailer.html.erb`): a `<style>` block, the SUL logo (`/images/sul_logo.png`), the SDR rosette logo (`/images/rosette_sdr.png`), an `<hr>`, then the body. Images resolve against `config.action_mailer.asset_host = "https://#{Settings.host}"` (`config/environments/production.rb`).
- The footer is not in the layout. Each template renders small ViewComponents in `app/components/emails/`:
  - `SalutationComponent`: "Dear <first_name>,", skipped if there is no first name.
  - `SignatureComponent`: "The Stanford Digital Repository Team".
  - `ContactComponent`: a "Contact us with questions." link to `new_contacts_url`.
  - `NewsletterComponent`: a newsletter subscribe link.
  - Per-work pieces in `emails/works/` (PURL, DOI, options, SearchWorks, changes).

  See for example `app/views/reviews_mailer/rejected_email.html.erb`.
- Report mailers attach a CSV (`attachments['item_report.csv']`) (`app/mailers/work_reports_mailer.rb`, `collection_reports_mailer.rb`).
- The contact form mailer sends to `Settings.jira_email` (`sdr-support@jirasul.stanford.edu`) and `Settings.support_email` (`sdr-support@lists.stanford.edu`). It uses the **submitter's address as `from:`** (`app/mailers/contacts_mailer.rb`, `config/settings.yml`).

## How emails are triggered

- `app/services/notifier.rb` defines event-name constants:
  - Participants: `MANAGER_ADDED`, `DEPOSITOR_ADDED`, `REVIEWER_ADDED`, the matching `*_REMOVED` events, and `PARTICIPANTS_CHANGED`.
  - Review: `REVIEW_REQUESTED`, `REVIEW_APPROVED`, `REVIEW_REJECTED`.
  - Deposit: `DEPOSIT_PERSIST_COMPLETE`, `ACCESSIONING_STARTED`, `ACCESSIONING_COMPLETE`.
  - Work: `OWNERSHIP_CHANGED`, `SHARE_ADDED`.

  `Notifier.publish` wraps `ActiveSupport::Notifications.instrument`. `Notifier.subscribe` yields the payload **only if `Settings.notifications.enabled`**.
- Publishers are model callbacks and state machines:
  - `after_create`/`after_destroy` on `CollectionManager`, `CollectionDepositor`, `CollectionReviewer`, and `Share`.
  - The review transitions in `app/models/work.rb`.
  - `DEPOSIT_PERSIST_COMPLETE`, `ACCESSIONING_STARTED`, `ACCESSIONING_COMPLETE` in `app/models/concerns/deposit_state_machine.rb`.
  - `DepositCollectionJob` (`PARTICIPANTS_CHANGED`).
  - `Admin::ChangeOwner` (`OWNERSHIP_CHANGED`).
- Subscriptions are wired in `config/initializers/subscriptions.rb`, in an `after_initialize` block. Simple events call a mailer directly. Fan-out events call a class in `app/subscription_handlers/*_subscription_mailer.rb`, which resolves recipients:
  - `WorkAccessioningCompletedSubscriptionMailer` sends to the work owner plus users with a `deposit` share. It sends `deposited_email` for a first version and `new_version_deposited_email` otherwise.
  - `WorkAccessioningStartedSubscriptionMailer` sends to the collection managers minus the current user.
  - `ReviewRequestSubscriptionMailer` sends to all collection reviewers.
  - `CollectionParticipantsChangedSubscriptionMailer` sends to managers and reviewers with a non-blank email. It is skipped if the collection flag is off, or on the very first save of a new collection.
  - `WorkOwnershipChangedSubscriptionMailer` sends to the current user and the new owner.
- H3 "accessioning complete" is driven by RabbitMQ: the sneakers worker `DepositCompleteJob` consumes `h3.deposit_complete` (DSA's `end-accession` workflow message) and calls `accession_complete!` (`app/jobs/deposit_complete_job.rb`).
- The same subscriptions also send SDR events (`Review*EventSubmitter`). Email is one consumer of the event bus, not the only one.

## Delayed / batched sending

- Event-driven emails all use `deliver_later` (`config/initializers/subscriptions.rb`, `app/subscription_handlers/*`, `app/controllers/contacts_controller.rb`). No `wait:`/`wait_until:` is used, and nothing is digested or batched. Each event produces one job per recipient.
- Jobs run on Solid Queue (`config.active_job.queue_adapter = :solid_queue` in `config/environments/production.rb`). Capistrano runs it as a systemd service on the app role (`set :solid_queue_systemd_role, :app` in `config/deploy.rb`). Emails use the default mailer queue name (no `deliver_later_queue_name` override).
- Mail that is already inside a job uses `deliver_now`: `WorkReportsJob`, `CollectionReportsJob`, and `TermsReminderEmailJob`.
- The terms reminder is H3's only scheduled email. A daily `whenever` cron (`config/schedule.rb`, 8:30 am) enqueues `TermsReminderEmailJob`. That job emails users whose `terms_reminder_email_last_sent_at` or `agreed_to_terms_at` is over a year old and records the send time on the user (`app/jobs/terms_reminder_email_job.rb`).
- (H2 also had daily draft-reminder crons, `WorkReminderGenerator` and `CollectionReminderGenerator`, in `happy-heron/config/schedule.rb`. H3 did not carry them over.)

## Delivery method and SMTP relay per environment

| Env | Delivery | Source |
|---|---|---|
| test | `:test` (`ActionMailer::Base.deliveries`); notifications disabled (`config/settings/test.yml`: `notifications.enabled: false`) | `config/environments/test.rb` |
| development | `:file` (writes to `tmp/mails/`), `perform_deliveries = true`, `raise_delivery_errors = false` | `config/environments/development.rb` |
| production (qa/stage/prod) | **unset**, so Rails default `:smtp` | `config/environments/production.rb` (the `smtp_settings` block is the commented-out Rails generator template) |

- Rails' default `:smtp` settings are `address: "localhost"`, `port: 25`, no user/password/auth, and `enable_starttls_auto: true` (`actionmailer-8.1.4/lib/action_mailer/delivery_methods.rb`).
- Every Puppet-managed Linux node includes `profile::postfix::nullclient` (`puppet/modules/role/manifests/basenode/linux.pp`).
  - Its Postfix sets `relayhost = smtp.stanford.edu` (`puppet/modules/profile/files/postfix/main-local-settings.ubuntu`).
  - By default it listens on `inet_interfaces = loopback-only` with `mynetworks = 127.0.0.0/8 [::1]/128` (`puppet/modules/profile/manifests/postfix/nullclient.pp`, `templates/postfix/nullclient/main-config.erb`).
- So in qa, stage, and prod, H3 (Passenger and Solid Queue on the VM itself) hands mail to the local Postfix, which relays it through `smtp.stanford.edu`. There are no SMTP credentials anywhere. The H3 hieradata (`hieradata/node/sul-h3-*.yaml`) and shared_configs contain no mail settings.
- Deployed settings (`shared_configs` `sul-h3-*:config/settings/production.yml`) set `host:` per environment and `notifications.enabled: true` in prod only. qa and stage don't set it, so they inherit `notifications.enabled: true` from `config/settings.yml`, and nothing in puppet overrides it with `SETTINGS__NOTIFICATIONS__ENABLED`. **qa and stage therefore send real email to real users' addresses.**
- No secret is involved in H3 mail delivery.

## From / reply-to

- `from: 'no-reply@sdr.stanford.edu'` for everything (`ApplicationMailer`). The exception is `ContactsMailer`, which uses the submitter's address as `from:`.
- No `reply_to:` is set anywhere. Replies are steered to the contact form by `ContactComponent`.

## URL host configuration

- Production: `config.action_mailer.default_url_options = { host: Settings.host }` and `asset_host = "https://#{Settings.host}"` (`config/environments/production.rb`). `Settings.host` comes from shared_configs: `sdr.stanford.edu` (prod), `sul-h3-stage.stanford.edu`, `sul-h3-qa.stanford.edu`. No protocol is set in `default_url_options`.
- Development: `{ host: "localhost", port: 3000 }`. Test: `{ host: "example.com" }`.

## User preferences / opt-out

- H3 has none per user. There is no preferences model, no unsubscribe link, and no `List-Unsubscribe` header.
- Each collection has two booleans, edited in the collection form's "Communication preferences for Managers and Depositors" section (`app/components/collections/edit/participant_notifications_component.html.erb`):
  - `email_when_participants_changed` gates `participants_changed_email`.
  - `email_depositors_status_changed` gates depositor invitation and removal emails.
- `Settings.notifications.enabled` is a global kill switch (`app/services/notifier.rb`). It does **not** cover the report emails, the terms reminder, or the contact form, which call mailers directly.
- H2 had per-user, per-collection opt-outs:
  - a `MailPreference` model with `MANAGER_TYPES`/`REVIEWER_TYPES` (`happy-heron/app/models/mail_preference.rb`);
  - an edit page (`app/controllers/mail_preferences_controller.rb`);
  - `Collection#opted_out_of_email?` checks before each send (`app/services/collection_observer.rb`, `work_observer.rb`).

  H2 also had a global `perform_deliveries` setting. H3 dropped all of this.

## Recipient resolution

- `mail(to: @user.email_address)`. `User.email_address` is the unique key, set at login by `User.upsert(user_attrs, unique_by: :email_address)` from the `REMOTE_USER` header, which is the Shibboleth eppn (`sunetid@stanford.edu`) (`app/controllers/concerns/authentication.rb`). `User#sunetid` strips `@stanford.edu` (`app/models/user.rb`).
- No directory lookup is done for preferred or alias addresses. Users who have never logged in still get email, because adding them by sunetid creates the row with `find_or_create_by!(email_address: "#{sunetid}@stanford.edu")` (`app/jobs/deposit_collection_job.rb`, `app/controllers/shares_controller.rb`, `app/controllers/admin/change_owner_controller.rb`).
- Admin notices go to `Settings.notifications.admin_email` = `h2-administrators@lists.stanford.edu` (`CollectionsMailer#first_version_created_email`).

## Testing approach

- Mailer specs (`spec/mailers/*_spec.rb`) build the mail with `described_class.with(...).x_email`. They assert `subject`, `to`, and `from`, and check the body with the custom matchers `match_body` and `match_body_in_order` (`spec/support/mail_matchers.rb`). They stub `Sdr::Repository.find`/`status` because the mailer fetches cocina.
- Subscriber specs (`spec/subscription_handlers/*`) use the `:active_job_test_adapter` metadata (`spec/support/active_job_test_adapter.rb`) and `ActionMailer::TestHelper#assert_enqueued_email_with`.
- `notifications.enabled` is false in test. System specs that exercise emails turn it on with `allow(Settings.notifications).to receive(:enabled).and_return(true)`, as in `spec/system/review_accept_work_spec.rb`.
- Previews live in `spec/mailers/previews/` (works, collections, terms) and are served at `/rails/mailers` in development. The README "Adding an email" section documents the publish → subscribe → mailer → test → preview recipe.
- There is no `letter_opener`. In development, mail is written to `tmp/mails/` via `delivery_method = :file`.

## Adopting the same delivery setup in Argo-B3

Argo-B3 today:

- `ApplicationMailer` has the generator default `from: 'from@example.com'` and the stock mailer layouts. There are no mailers yet.
- Production `default_url_options` is `{ host: "example.com" }`, and there is no delivery method config.
- Jobs already run on Solid Queue (`config/environments/production.rb`), in a separate Kamal `job` role (`config/deploy.yml`). `deliver_later` would work as-is.
- Users already have `email_address` = Shibboleth `REMOTE_USER` (`app/controllers/concerns/authentication.rb`), so recipient resolution matches H3.

The gap is delivery. H3's setup relies on the app process reaching Postfix on `localhost:25`. Argo-B3's app and job containers run on Kamal's `kamal` Docker bridge network. There, `localhost` is the container itself, and the host's Postfix listens on loopback only. Two changes are needed:

1. **Puppet (ops)**, per Argo-B3 host (`hieradata/node/argo-b3-{qa,stage,prod}-a.stanford.edu.yaml`):
   - Set `postfix_container: { value: true }`. This switches the null client to the `main-config.container.erb` template, with `inet_interfaces = all`.
   - Set `profile::postfix::nullclient::mynetworks` to include the Docker bridge range so Postfix accepts relay from containers.
   - Open port 25 to that range in `profile::firewall::openports`.

   There is a precedent: `sul-libsys-airflow-stage` and the `lockss-delta-*` nodes already set `postfix_container` with `mynetworks: '127.0.0.0/8 [::1]/128 192.0.0.0/8 172.0.0.0/8'`. The Argo-B3 nodes already open Postgres 5432 to `172.16.0.0/12` for the same reason, and that is the obvious range to mirror for port 25.
2. **App (Argo-B3)**:
   - In `config/environments/production.rb`, set `delivery_method = :smtp` and `smtp_settings = { address: "host.docker.internal", port: 25 }`. Both Kamal roles already have `add-host: "host.docker.internal:host-gateway"` (`config/deploy.yml`). Postfix's certificate won't match `host.docker.internal`, so if the null client advertises STARTTLS, `enable_starttls_auto: false` (or `openssl_verify_mode: "none"`) may be needed. This is unverified; check on stage.
   - Set `default_url_options = { host: Settings.host, protocol: "https" }` and `asset_host`, with the host supplied per destination via a clear `SETTINGS__HOST` in `config/deploy.<dest>.yml`.
   - Set `default from:` (e.g., `no-reply@sdr.stanford.edu`, to match H3) in `ApplicationMailer`.
   - Add a notifications kill switch like H3's. Decide deliberately whether qa and stage send to real users: H3's do.
   - No secrets are needed, because the relay is unauthenticated. If an authenticated relay were chosen instead, its credentials would go in Vault as `SETTINGS__*` env vars listed under `env.secret` in `config/deploy.yml`, not in shared_configs.

   An alternative avoids the Puppet change: point `smtp_settings` directly at `smtp.stanford.edu`. Whether that relay accepts unauthenticated mail from these hosts is not established by these sources. H3 goes through the local null client, so that is the proven route.

What else to copy from H3: the `Notifier` publish/subscribe split, the email ViewComponents for salutation, signature, and contact, mailer specs with body matchers, and previews under `spec/mailers/previews`. Before designing preferences, it's worth deciding whether Argo-B3 wants H2-style per-user opt-out, since H3 deliberately has none.
