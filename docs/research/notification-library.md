# Which notification library, if any? (#1427)

Researched 2026-11-16 for [#1427](https://github.com/sul-dlss/argo-b3/issues/1427), part of [#1371](https://github.com/sul-dlss/argo-b3/issues/1371).

Sources: Noticed source at `excid3/noticed` `0d91fc5` (v3.1.1); activity_notification source at `simukappu/activity_notification` `5f9902b` (v2.7.4); RubyGems and GitHub APIs (2026-11-16); Argo-B3 `origin/main` `9f154f2b`.

## Recommendation

**Use Noticed (v3.x).** It covers the hard parts (one row per recipient per event, a delayed email that is skipped at delivery time, per-recipient conditions) with a small footprint: two tables and only Rails as a dependency. Argo-B3 still builds the Turbo toast delivery method (about 10 lines), the preferences store, and the 30-day cleanup job. activity_notification doesn't fit: its subject must be an Active Record record, and it pulls in jquery-rails. Hand-rolling is viable at about 200 to 300 lines, but it would rebuild what Noticed already does.

## Noticed

### Maintenance and footprint

- Latest release 3.1.1 on 2026-11-03; 3.1.0 on 2026-09-30, 3.0.0 on 2025-12-31 (`CHANGELOG.md`, git tags). About 7.5M downloads, 2.7k stars, 0 open issues, not archived (RubyGems and GitHub APIs).
- Its only runtime dependency is `rails >= 7.1.0` (`noticed.gemspec`). CI runs Rails 7.1, 7.2, 8.0, 8.1 and `main` on Ruby 3.3, 3.4 and 4.0 (`.github/workflows/ci.yml`). 3.1.0 already handles Rails 8.2's `GlobalID::Locator::RecordNotFound` (`lib/noticed/coder.rb`).
- It adds two tables, `noticed_events` and `noticed_notifications`, plus a later `notifications_count` column (`db/migrate/*.rb`). It has no views, controllers, routes, or JS. The v3 breaking changes only drop old Rails versions and change ephemeral lambda context (`CHANGELOG.md`).

### Data model

- `noticed_events`: STI `type` (the Notifier class, i.e., the **kind**), optional polymorphic `record`, `params` jsonb (on Postgres), and timestamps (`20231215190233_create_noticed_tables.rb`). `Noticed::Event` declares `belongs_to :record, polymorphic: true, optional: true` (`app/models/noticed/event.rb`).
- `noticed_notifications`: one row per recipient (`type`, `event_id`, polymorphic `recipient` NOT NULL, `read_at`, `seen_at`). `Event#deliver` bulk-inserts them in one transaction with the event (`app/models/concerns/noticed/deliverable.rb`).
- **Non-AR subject (druid + version):** this works. Leave `record` nil and pass `Notifier.with(druid:, version:, ...)`. Params are serialized with Active Job's argument serializer, so strings, numbers, and GlobalID records all round-trip (`lib/noticed/coder.rb`). To query by druid, use `params @> '{"druid": ...}'` (the same jsonb containment that `has_noticed_notifications` uses on Postgres, `lib/noticed/has_notifications.rb`), or add a stored generated column, as the README's "Customizing the Database Models" section shows. If a Multi-Item Deposit or bulk action is the subject, it can be the `record`.
- **Render params:** `params` holds them, and `required_params` validates them at deliver time (README "Required Params").
- **No read/unread:** `read_at`/`seen_at` and the `Readable` scopes are there, but nothing requires their use (`app/models/concerns/noticed/readable.rb`). Note that #1371 says acting marks the in-app notification read; `read_at` would cover that if #1376 wants it.
- **Recipients must be AR records** (`recipient_type`/`recipient_id`, NOT NULL; `recipient_attributes_for` calls `recipient.class.base_class.name`). Free-form email additional recipients (#1379) would need a `User` row or a separate path.

### i18n

- `notification_methods do ... end` defines rendering helpers on the per-notifier `Notification` subclass. `t(".title")` resolves to `notifiers.<notifier_underscored>.notification.title` (`lib/noticed/translation.rb`, README "Translations"). Rails URL helpers are included in both models.
- Unverified: Argo-B3's i18n-tasks lint may not resolve these relative keys outside views and may need an ignore or `used_keys` pattern.

### Delivery

- `Notifier.with(params).deliver(users, **job_options)` saves the event and notifications, then enqueues `Noticed::EventJob`. That job enqueues one delivery job per notification per `deliver_by` (`app/jobs/noticed/event_job.rb`). Each delivery method is itself an Active Job, so Solid Queue runs everything with no extra infrastructure.
- **Turbo toast:** the built-in `:action_cable` method calls `channel.broadcast_to(stream, message)` (`lib/noticed/delivery_methods/action_cable.rb`). That isn't the Turbo Streams stream name `broadcast_toast` uses (`Turbo::StreamsChannel.broadcast_append_to('notifications', user, ...)`). Use a custom delivery method instead (`deliver_by :toast, class: "DeliveryMethods::Toast"`, whose `deliver` calls the existing toast rendering). The README "Custom Delivery Methods" section shows this pattern for Turbo Streams.
- **Email:** `deliver_by :email` with `config.mailer`/`config.method` calls `mailer.with(params).<method>` and then `deliver_now`, or `deliver_later` if `config.enqueue` is set. The params include `notification`, `record`, and `recipient` (`lib/noticed/delivery_methods/email.rb`). This plain Action Mailer path matches H3 (#1372).

### Delayed email cancelled by a later user action

This is supported, and it is the README's own "Fallback Notifications" pattern:

```ruby
deliver_by :email do |config|
  config.mailer = "NotificationMailer"
  config.method = :notification
  config.wait = 15.minutes
  config.unless = -> { resolved? } # evaluated in the Notification, when the delayed job runs
end
```

- `wait`/`wait_until` are passed to `job.set(...)`, so the job is scheduled in Solid Queue. They can be lambdas evaluated per notification (`app/models/noticed/deliverable/deliver_by.rb#computed_options`).
- `if`/`unless` run inside `DeliveryMethod#perform`, so **at delivery time, after the wait**. A falsey `if` or truthy `unless` returns before `deliver` (`lib/noticed/delivery_method.rb`). The README says the same: "runs after the `wait` if configured".
- So "cancel" means the scheduled job still runs and does nothing; the job is not removed from Solid Queue. The condition can read domain state directly (e.g., whether the Multi-Item Deposit has left the step it was notified about), or a flag that the action sets (`read_at`, or a custom `resolved_at` column). Reading domain state means the action doesn't have to write anything.
- `before_enqueue` (`throw :abort`) runs at enqueue time instead, which suits static checks such as an opted-out channel (`DeliverBy#perform?`).
- Deleting the notification also cancels the email. The default `Noticed.parent_class` is `Noticed::ApplicationJob`, which has `discard_on ActiveJob::DeserializationError` (`app/jobs/noticed/application_job.rb`, `lib/noticed.rb`). Argo-B3's `ApplicationJob` has that line commented out, so keep the default parent class or add the discard.

### Per-user preferences

Noticed has no preferences store. Its documented approach is `config.if = -> { recipient.<pref>? }` or `before_enqueue` per delivery method (README "Tip: Capture User Preferences"). An Argo-B3-owned table or jsonb column keyed by kind × channel would plug in as one shared lambda, for example a module included in every notifier (README "Extracting Delivery Method Configurations"). Turning off the in-app inbox would mean not creating the notification row at all, so filter recipients before calling `deliver`.

### structure.sql

`rails noticed:install:migrations` copies the two migrations into `db/migrate` (README "Installation"). They are ordinary `create_table` and `add_column` migrations (jsonb on Postgres), so `db:migrate` dumps them to `db/structure.sql` like any other migration. Argo-B3 sets `schema_format: sql` in `config/database.yml`. The README says to edit the copied migration to add columns or indexes; Argo-B3 needs an index on `noticed_notifications (recipient_type, recipient_id, created_at)` for the "last 25" inbox.

### Retention

Noticed doesn't delete anything automatically. Add a recurring Solid Queue job (`config/recurring.yml`, next to `content_cleanup`) that deletes old events, e.g. `Noticed::Event.where(created_at: ...30.days.ago)`. `has_many :notifications, dependent: :delete_all` takes the notifications with them when destroyed. In bulk, delete the notifications first, or add an FK `ON DELETE CASCADE` in the migration.

### Costs and caveats

- STI `type` stores class names, so renaming a notifier needs a data migration (README "Renaming Notifiers").
- `read_at`/`seen_at` columns go unused unless #1376 uses them.
- 3.1.0's `EventJob` uses `perform_all_later`, which skips Active Job enqueue callbacks (`CHANGELOG.md`). Argo-B3 doesn't depend on those.

## activity_notification (rejected)

- It is maintained: 2.7.4 on 2026-11-13, CI Gemfiles through Rails 8.1, about 1.1M downloads.
- Runtime dependencies are `railties >= 7.0, < 8.2`, `jquery-rails`, and `swagger-blocks` (`activity_notification.gemspec`). The upper bound means a release is needed before Rails 8.2, and jquery-rails is a dependency Argo-B3 otherwise wouldn't have.
- `notifications.notifiable` is polymorphic **NOT NULL** (`lib/generators/templates/migrations/migration.rb`). A druid + version subject would need a stand-in AR record.
- It has more than Argo-B3 needs: generated controllers, views, routes, a REST API with OpenAPI, Mongoid and Dynamoid ORMs, grouping, and batch emails. It does have a built-in `subscriptions` table (per target × key, with `subscribing` and `subscribing_to_email`), but that is per key, not per kind × every channel.
- Its delayed fallback ("cascading notifications") stops on **opened** (read) state (`docs/Functions.md`, "Cascading notifications"), while #1371 wants cancellation on user action, not on viewing.

Other candidates: the `notifications` gem (huacnlee) last released 1.1.0 in 2020-10 and its GitHub repo no longer resolves, so it was not considered further.

## Hand-rolled, for comparison

Roughly 200 to 300 lines plus specs:

- a `notifications` table (user, kind, nullable polymorphic subject, druid, version, params jsonb, created_at, index on user + created_at)
- a `Notifier`/`Notifications::Deliver` service that inserts a row per recipient, broadcasts the toast, and enqueues `NotificationEmailJob.set(wait:)`
- that job checking a cancellation condition and the preferences before `deliver_now`
- an i18n rendering helper per kind
- the recurring cleanup job

Argo-B3 needs the preferences, toast, and cleanup either way. What hand-rolling would rebuild is Noticed's event/recipient fan-out, the per-channel `if`/`unless`/`wait` DSL, and the i18n scoping. The upside is that there's no STI coupling and no `read_at`/`seen_at` columns, and the schema could have a first-class `druid`/`version`.
