#!/usr/bin/env bash
# Restarts the services bin/setup-claude-cloud-env starts (Postgres, Docker, and the
# Solr containers) when they aren't running. A cloud container that goes idle is shut
# down, killing them; when the session resumes, the setup script doesn't run again.
# Fast when everything is already up (e.g., right after the setup script ran).
set -uo pipefail

[[ "${CLAUDE_CODE_REMOTE:-}" == "true" ]] || exit 0

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0

# Keep in sync with bin/setup-claude-cloud-env.
solr_services=(solr solr-test1 solr-test2 solr-test3 solr-test4)
solr_ports=(8983 8984 8985 8986 8987)

# Warnings go to stdout, which a SessionStart hook adds to the session's context.
warn() { echo "session-start hook: $*"; }

wait_for() {
  local seconds="$1"
  shift
  for _ in $(seq "$seconds"); do
    "$@" >/dev/null 2>&1 && return 0
    sleep 1
  done
  return 1
}

solr_up() { curl -fsS --noproxy '*' "http://localhost:$1/solr/argo/admin/ping"; }

all_solr_up() {
  local port
  for port in "${solr_ports[@]}"; do
    solr_up "$port" >/dev/null 2>&1 || return 1
  done
}

if ! pg_isready --host localhost >/dev/null 2>&1; then
  service postgresql start >/dev/null 2>&1
  wait_for 30 pg_isready --host localhost || warn "Postgres did not start."
fi

all_solr_up && exit 0

if ! docker info >/dev/null 2>&1; then
  # Started directly, as in bin/setup-claude-cloud-env: the init script fails in
  # cloud containers, which don't permit its ulimit call.
  setsid dockerd >>/var/log/dockerd.log 2>&1 </dev/null &
  if ! wait_for 60 docker info; then
    warn "Docker did not start (see /var/log/dockerd.log), so Solr is not running."
    exit 0
  fi
fi

if ! docker compose up --detach "${solr_services[@]}" >/dev/null 2>&1; then
  warn "docker compose up failed for ${solr_services[*]}, so Solr is not running."
  exit 0
fi
for port in "${solr_ports[@]}"; do
  wait_for 120 solr_up "$port" || warn "Solr on port $port did not answer its ping."
done
exit 0
