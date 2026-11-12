# Consuming DSA workflow events vs polling DSA

Research for sul-dlss/argo-b3#1373 (part of #1371, user notifications). The question: what would it take for
Argo-B3 to detect post-accessioning outcomes (a deposit's process erroring; accessioning completing for an item
or for every item in a Multi-Item Deposit) by consuming DSA's RabbitMQ workflow events, versus polling DSA?

This lays out facts and trade-offs; it does not make the decision.

Sources are local checkouts under `/Users/jlittman/data/sdr/` (dor-services-app at `d6dcfd15`, pre-assembly at
`eb1242e7`, happy-heron, dor-services-client, shared_configs), GitHub for H3 (`sul-dlss/hungry-hungry-hippo`),
the kicks/sneakers gem (`ruby-amqp/kicks`), the bunny gem (`ruby-amqp/bunny`), the sul-dlss/DevOpsDocs
`projects/dor-services-app/messaging.md`, and Argo-B3 `main` at `0aca5104`.

## 1. What DSA publishes on `sdr.workflow`

### When

`Workflow::NextStepService#enqueue_next_steps` publishes only when the step's status is `error`, or the step is
`accessionWF` / `end-accession` / `completed`
(`dor-services-app/app/services/workflow/next_step_service.rb:29`, `last_accession_step?` at line 77).

`enqueue_next_steps` runs after every process update through `Workflow::ProcessService#update_status`
(`app/services/workflow/process_service.rb:73`), and on workflow creation for the first step
(`app/services/workflow/creator.rb`). Both error paths, the in-DSA robots (`app/jobs/robots/robot.rb:64`) and the
HTTP API used by external robots (`app/controllers/workflow_processes_controller.rb:7`), go through
`ProcessService.update_error`, so every process error in every workflow is published. The only callers that pass
`enqueue_next_steps: false` are in `app/jobs/robots/dor_repo/release/start.rb`.

Not published: completion of any other step (e.g., `assemblyWF` finishing, a version closing), a retry (status
back to `waiting`), a skip, or a completed step after an earlier error. "Error resolved" can only be inferred from a
later `end-accession.completed` for the same druid and version.

### Exchange, routing key, publisher

- Topic exchange `sdr.workflow` (`app/services/notifications/workflow_step_updated.rb:29`).
- Routing key `"#{step.process}.#{step.status}"`, e.g. `end-accession.completed`, `shelve.error`
  (line 22). The workflow name is not in the routing key, so `*.error` matches errors in every workflow.
- Published with Bunny's `exchange.publish` and no options (`Notifications::RabbitChannel`, a singleton channel
  per process). Bunny defaults to `persistent: true` (delivery mode 2) and `mandatory: false`
  (`ruby-amqp/bunny` `lib/bunny/channel.rb` `basic_publish`); there are no publisher confirms. A message published
  while no queue is bound is dropped silently.
- Publishing is gated by `Settings.rabbitmq.enabled` (default `false` in DSA's `config/settings.yml`; `true` in
  `shared_configs` `origin/dor-services-app-prod`).

### Payload

`step.attributes_for_process.merge(action: 'workflow updated', druid: step.druid)` as JSON
(`app/models/workflow_step.rb:77-94`):

| key | content |
|---|---|
| `druid` | with `druid:` prefix |
| `action` | always `"workflow updated"` |
| `name` | process name, e.g. `end-accession` |
| `status` | `error` or `completed` |
| `version` | the object version the step belongs to |
| `activeVersion` | boolean |
| `laneId`, `lifecycle`, `note`, `elapsed`, `attempts` | step bookkeeping |
| `datetime` | ISO 8601 (completed_at for completed steps, updated_at otherwise) |
| `context` | version context, JSON-encoded string |
| `errorMessage` | only when the step has an error message |

The payload does **not** include the workflow name. An error message identifies the process but not whether it
was in `assemblyWF`, `accessionWF`, `ocrWF`, etc., without a lookup (DSA workflows API or Solr `wf_error_ssim`,
which is `workflow:process:message`). It carries no user, no Argo-B3 identifiers, and no cocina.

## 2. How existing consumers do it

All three consumers use the same pattern: Bunny + Sneakers (or its successor kicks), a rake task that declares a
durable queue and binds it to `sdr.workflow`, and a separate long-running Sneakers process managed by systemd via
dlss-capistrano.

| | pre-assembly | H3 (hungry-hungry-hippo) | H2 (happy-heron, legacy) |
|---|---|---|---|
| Gem | `sneakers` 2.11 + `bunny` (`Gemfile:3,23`) | `kicks` ("formerly sneakers") + `bunny` (`Gemfile:45,65`) | `sneakers ~> 2.11`, `bunny ~> 2.17` |
| Queue | `preassembly.accession_complete` | `h3.deposit_complete` | `h2.deposit_complete` |
| Bindings | `end-accession.completed`, `*.error` (`lib/tasks/rabbit.rake`) | `end-accession.completed` (`lib/tasks/rabbitmq.rake`) | `end-accession.completed` |
| Worker | `AccessionCompleteJob` (`app/jobs/accession_complete_job.rb`) | `DepositCompleteJob` (`app/jobs/deposit_complete_job.rb`) | `DepositCompleteJob` |
| Process | systemd `sneakers` service (`config/deploy.rb:38-64`) | systemd `sneakers` service (`config/deploy.rb:70-86`) | same |
| Queue setup | `rake rabbitmq:setup` before `sneakers_systemd:start` on deploy | same | same |
| Health check | OkComputer `RabbitQueueExistsCheck` | OkComputer (per GitHub search) | OkComputer `rabbit-queues` |

How they use the messages:

- pre-assembly matches `druid` + `version` from the message against its own `Accession` rows (`in_progress` →
  `completed`/`failed`), then enqueues `JobRunCompleteJob` per affected job run, which is how it knows when every
  object in a batch is done (`accession_complete_job.rb`). It filters to its own objects by DB lookup, since it
  receives every SDR error and every accession completion.
- H3 looks up the `Work`/`Collection` by druid, re-syncs from cocina (`Sdr::Repository.find`), transitions its
  state machine only if it is `accessioning?`, and broadcasts a Turbo refresh
  (`Turbo::StreamsChannel.broadcast_refresh_to object`). Messages for objects it doesn't know raise
  `RecordNotFound` (H2 retried 10x with sleep for a race on druid assignment).
- Sneakers initializers are identical: `Bunny.new(hostname:, vhost:, username:, password:)` from `Settings.rabbitmq`,
  Honeybadger error reporter (pre-assembly `config/initializers/sneakers.rb`, H3 `config/initializers/kicks.rb`).

DSA itself also has a `dor.indexing-by-druid` durable queue bound to `sdr.workflow` with `#`
(`dor-services-app/lib/tasks/rabbitmq.rake:22-26`); no consumer of it was found in DSA, so it appears to be a
leftover (not verified on the broker).

### Deployed settings (key names only)

- H3, pre-assembly, DSA prod (`shared_configs` `origin/sul-h3-prod`, `origin/sul-preassembly-prod`,
  `origin/dor-services-app-prod`, `config/settings/production.yml`): `rabbitmq.enabled: true`,
  `rabbitmq.hostname: sul-rabbit-prod`, `rabbitmq.vhost: workflow`, `rabbitmq.username` set; `password` is not in
  shared_configs (supplied from Vault/env). Broker dashboards: `sul-rabbit-{prod,stage,qa}.stanford.edu`
  (DevOpsDocs `messaging.md`).
- Argo-B3 already has RabbitMQ wired, because it publishes events via `dor-event-client`
  (`config/initializers/dor_event_client.rb`): `config/deploy.yml` sets `SETTINGS__RABBITMQ__VHOST: workflow` and
  `SETTINGS__RABBITMQ__ENABLED: true`, secrets `SETTINGS__RABBITMQ__USERNAME` / `SETTINGS__RABBITMQ__PASSWORD`
  (`.kamal/secrets-common`, from Vault via `bin/kamal-otk` or Jenkins), and per-destination
  `SETTINGS__RABBITMQ__HOSTNAME` (`config/deploy.{prod,stage,qa}.yml`). `bunny` 2.24 is already in
  `Gemfile.lock` (via dor-event-client). Argo-B3's shared_configs branch has no `rabbitmq` key.
- Unknown from code: whether Argo-B3's RabbitMQ user has configure/read permissions on the `workflow` vhost
  (needed to declare a queue, bind it, and consume); it is only known to publish. Check on the broker.

## 3. What a consumer in Argo-B3 would take

- **Gem**: add `kicks` (as H3 did) or use Bunny directly (`queue.subscribe`); bunny is already present.
- **Queue declaration**: a durable queue (e.g. `argo-b3.workflow`) bound to `sdr.workflow` with
  `end-accession.completed` and `*.error`. Existing apps run a `rabbitmq:setup` rake task before starting the
  consumer. In Kamal this could be a `pre-deploy` hook, part of the consumer role's start command, or done by the
  worker itself (Sneakers' `from_queue` declares the queue; by default it also binds to an exchange named
  `sneakers` unless `exchange:`/`routing_key:`/`bind: false` is given, `ruby-amqp/kicks` `lib/sneakers/queue.rb`).
  `.kamal/hooks/` currently has only `post-deploy`. The queue must exist before the first deposit that should be
  observed, since unbound messages are dropped.
- **Process**: a new long-running process. Kamal fits this as another role alongside `web` and `job`, e.g.
  `consumer: cmd: bin/rails sneakers:run` with `WORKERS=...` (kicks provides `sneakers:run` in
  `sneakers/tasks`), `add-host: host.docker.internal:host-gateway` for Postgres, and a `stop_timeout`. It can't run
  inside Solid Queue workers (they poll Postgres, not AMQP). A Sneakers process forks `workers` (default 4) with
  `threads` (default 10) each, each holding DB connections; DSA uses `workers: 1` for a low-volume queue.
- **Worker logic**: map `druid` + `version` to Argo-B3 state (e.g. Item Deposits, user deposits), ignore the rest
  (most traffic is not Argo-B3's), look up the workflow name for errors if needed, then notify (Solid Cable is
  configured, `config/cable.yml`; `StageFilesJob` already broadcasts Turbo refreshes and toasts). Handing off to a
  Solid Queue job keeps the consumer thin and gives Solid Queue retries.
- **Health**: OkComputer queue-exists check as in pre-assembly/H3; monitoring of queue depth on the broker.
- **Local dev/test**: `compose.yaml` has no RabbitMQ; specs would call the worker's `work` directly (as
  pre-assembly/H3 do).

## 4. Delivery guarantees

| Concern | Behavior | Source |
|---|---|---|
| Consumer downtime (deploy, crash) | Messages accumulate in the durable queue and are delivered on reconnect: durable queue + persistent messages. No TTL or max-length is set by any existing app, so a long outage grows the queue unbounded. | kicks `QUEUE_OPTION_DEFAULTS durable: true`; bunny `persistent` default true |
| Queue not yet declared | Messages are dropped (topic exchange, `mandatory: false`). | bunny `basic_publish` |
| Broker restart | Persistent messages in durable queues survive. | AMQP semantics |
| Publish failure in DSA | No publisher confirms; if publishing raises, the step update is already committed (it happens after the transaction), so the event is lost while the step state is correct. | `process_service.rb:68-73`, `next_step_service.rb:29` |
| Ack | Manual ack (`ack: true`), `prefetch: 10`; a crash before ack redelivers, so at-least-once: duplicates possible. Handlers must be idempotent (pre-assembly's state filter is). | kicks `Configuration::DEFAULTS` |
| Retries | Default `Oneshot` handler: an exception rejects without requeue, i.e. the message is discarded (reported to Honeybadger). kicks offers a `Maxretry` handler with retry/error queues; no SDR app uses it. | kicks `handlers/oneshot.rb` |
| Ordering | One queue is FIFO, but Sneakers processes with multiple workers/threads, so handling order is not guaranteed. Each druid's `error` and `end-accession.completed` are usually far apart in time. | kicks defaults `workers: 4`, `threads: 10` |
| Missed outcomes | Anything that changes outcome without a message (retry then success in assemblyWF only, a version closed without accessionWF, events lost above) is invisible to a pure consumer; a reconciliation poll would catch it. | §1 |

## 5. Polling DSA / Solr

### Endpoints

| Call | Returns | Cost |
|---|---|---|
| `Dor::Services::Client.objects.statuses(object_ids:)` → `POST /v1/objects/versions/status` | per druid: `versionId`, `open`, `openable`, `assembling`, `accessioning`, `closeable`, `discardable`, `versionDescription` | 1 HTTP call per batch; DSA does a handful of SQL queries for the whole batch (`VersionBatchStatusService`). Argo-B3 wraps it in `Sdr::VersionService.statuses` with `STATUSES_SLICE_SIZE = 25`. No error info. |
| `object(druid).version.status` → `GET .../versions/status` | same, one druid | 1 call per druid |
| `object(druid).workflows.list` → `GET .../workflows` | all workflows (XML) with process statuses and error messages | 1 call per druid |
| `object(druid).workflow(name).find` / `.process(name)` | one workflow / process | 1 call per druid per workflow (Argo-B3 `Sdr::WorkflowService`) |
| Solr (`Searchers::ItemByDruid`, `fq id:(...)`) | any indexed field for N druids | 1 query per batch |

There is no DSA batch endpoint for workflow errors.

### Solr fields that can substitute

DSA reindexes synchronously after every process update (`next_step_service.rb:33`), with
`commitWithin: 5000` (`app/services/indexer.rb:21`), so Solr reflects a step change within about 5 seconds.

- `wf_error_ssim` (`Search::Fields::WORKFLOW_ERRORS`): `workflow:process:message` for each errored process in
  the most recent run of each workflow (`indexing/indexers/workflow_process_indexer.rb:56`,
  `workflows_indexer.rb`). Unlike the event, it includes the workflow name.
- `wf_error_latest_dtpsidv`: time of the most recent current error (`indexing/workflow_solr_document.rb:13`).
- `processing_status_text_ssidv` / `status_ssi`: milestone-derived status for the current version, e.g.
  `Accessioned` (`indexing/workflow_fields.rb`), with `current_version_ipsidv`.
- `accessioned_latest_dtpsidv`: latest accessioned milestone time.
- `wf_wps_ssimdv`: `workflow:process:status` for every process.

`MultiItemDeposit::ObjectStatusPresentersBuilder` already combines one Solr query (`id`, `wf_error_ssim`) with
batched version statuses on each Multi-Item Deposit show page view (`multi_item_deposit_actions_controller.rb:33`).

### Cost per poll

| Scope | Version status (DSA) | Errors (Solr) | Per-druid alternative |
|---|---|---|---|
| Single item | 1 DSA call | 1 Solr query | 1 `workflows.list` |
| Multi-Item Deposit of N items | ceil(N/25) DSA calls at the current slice size (the endpoint takes any list; 25 is Argo-B3's choice) | 1 Solr query (or ceil(N/rows limit)) | N `workflows.list` calls |
| All in-flight objects across Argo-B3 | one batched set over all tracked druids | one query, or a filter like `wf_error_latest_dtpsidv:[since TO *]` | not practical |

Completion for an item can be read as `!open && !assembling && !accessioning` for the deposited version (or Solr
`processing_status_text_ssidv:Accessioned` at that `current_version_ipsidv`); "every item done" is that across
all N, with errored items counted separately.

### Scheduling

Solid Queue's scheduler (part of `bin/jobs`, the existing Kamal `job` role) runs `config/recurring.yml` tasks;
schedules are Fugit expressions, down to `every second`. Duplicate enqueues across multiple schedulers are
prevented by a unique `(task_key, run_at)` (Solid Queue README "Recurring tasks"). Argo-B3 already has three
production recurring tasks. A poll job would need its own record of what is in flight (e.g. deposited druid +
version + who to notify) to know what to poll and when to stop, plus a concurrency limit so slow runs don't
overlap. Latency is the poll interval plus Solr's ~5s commit.

## 6. Comparison

| | Consumer (RabbitMQ) | Polling (DSA batch status + Solr) | Hybrid (consumer + reconciliation poll) |
|---|---|---|---|
| Latency | Seconds | Poll interval (+~5s Solr commit) | Seconds; poll bounds worst case |
| New infrastructure | Durable queue + bindings on `workflow` vhost; possibly broker permissions for Argo-B3's user; new Kamal role; queue-setup step; queue health check | None (Solid Queue recurring task in existing `job` role) | Both |
| New gems | `kicks` (or raw Bunny) | None | `kicks` |
| Credentials | Already wired (`SETTINGS__RABBITMQ__*`) | DSA token and Solr already wired | Already wired |
| Load | Receives every SDR error and every accession completion, filtered locally (volume not measured; see broker dashboard) | Proportional to in-flight objects and poll frequency: per poll ceil(N/25) DSA calls + 1 Solr query | Consumer volume + infrequent poll |
| Error detail | Process + message, no workflow name | Solr gives `workflow:process:message` | Solr on demand |
| Completion signal | `end-accession.completed` only (accessionWF) | Any derivable state (assembling, accessioning, closed, milestones) | Both |
| Missed events | Lost if queue missing, publish fails, or handler raises (Oneshot); queued during downtime otherwise | None by construction; state is re-read each poll | Poll catches what the consumer misses |
| Duplicates / order | At-least-once, unordered; idempotent handlers needed | Must detect transitions (store last-seen state) to notify once | Both concerns |
| Testability locally | No RabbitMQ in `compose.yaml`; unit-test worker `work` | Ordinary job specs with stubbed DSA/Solr | Both |
| Precedent in SDR | pre-assembly (batch completion), H3 (deposit completion) | Argo-B3's Multi-Item Deposit page (on page view) | None found |
