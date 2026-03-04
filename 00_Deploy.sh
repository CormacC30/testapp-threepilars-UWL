#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# Utility
# ──────────────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/deploy-$(date +%Y%m%d-%H%M%S).log"

log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  echo "$msg"
  echo "$msg" >> "$LOG_FILE"
}

die() {
  log "ERROR: $*"
  exit 1
}

run_script() {
  local script="${SCRIPT_DIR}/$1"
  log "Running: $1"
  bash "$script" || die "Script failed: $1"
}

# oc create wrapper — tolerates "already exists" errors, propagates real ones
oc_create() {
  local output exit_code=0
  output=$(oc create "$@" 2>&1) || exit_code=$?
  if [ $exit_code -eq 0 ]; then
    echo "$output"
  elif echo "$output" | grep -q "already exists"; then
    log "  (already exists — skipping)"
  else
    echo "$output" >&2
    return $exit_code
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Readiness checks
# ──────────────────────────────────────────────────────────────────────────────

# Wait for all CSVs in a namespace to reach phase Succeeded
wait_for_all_csvs() {
  local namespace=$1 timeout=${2:-900}
  local interval=20 elapsed=0
  log "Waiting for all CSVs in '$namespace' to succeed (timeout: ${timeout}s)..."
  while [ $elapsed -lt $timeout ]; do
    local total pending
    total=$(oc get csv -n "$namespace" --no-headers 2>/dev/null | wc -l)
    if [ "$total" -eq 0 ]; then
      log "  No CSVs found yet... (${elapsed}s elapsed)"
      sleep $interval
      elapsed=$((elapsed + interval))
      continue
    fi
    pending=$(oc get csv -n "$namespace" --no-headers 2>/dev/null \
              | grep -vc "Succeeded" || true)
    if [ "$pending" -eq 0 ]; then
      log "  All $total CSVs in '$namespace' are Succeeded"
      return 0
    fi
    log "  $pending/$total CSVs not yet Succeeded (${elapsed}s elapsed)"
    sleep $interval
    elapsed=$((elapsed + interval))
  done
  die "Timed out waiting for all CSVs in '$namespace'"
}

# Wait for an OLM Subscription's CSV to reach phase Succeeded
wait_for_subscription() {
  local name=$1 namespace=$2 timeout=${3:-900}
  local interval=20 elapsed=0
  log "Waiting for subscription '$name' in '$namespace' (timeout: ${timeout}s)..."
  while [ $elapsed -lt $timeout ]; do
    local csv phase
    csv=$(oc get subscription "$name" -n "$namespace" \
          -o jsonpath='{.status.installedCSV}' 2>/dev/null || true)
    if [ -n "$csv" ]; then
      phase=$(oc get csv "$csv" -n "$namespace" \
              -o jsonpath='{.status.phase}' 2>/dev/null || true)
      if [ "$phase" = "Succeeded" ]; then
        log "  '$name' ready (CSV: $csv)"
        return 0
      fi
      log "  CSV '$csv' phase: ${phase:-Unknown} (${elapsed}s elapsed)"
    else
      log "  Waiting for installedCSV... (${elapsed}s elapsed)"
    fi
    sleep $interval
    elapsed=$((elapsed + interval))
  done
  die "Timed out waiting for subscription '$name' in '$namespace'"
}

# ──────────────────────────────────────────────────────────────────────────────
# Error trap
# ──────────────────────────────────────────────────────────────────────────────
trap 'log "FATAL: deploy aborted at line $LINENO (exit code $?)"' ERR

# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────
cd "$SCRIPT_DIR"

log "=== Starting deployment (log: $LOG_FILE) ==="

# ── Phase 1: ODF ─────────────────────────────────────────────────────────────
log "--- Phase 1: Install ODF ---"
run_script "00_Install_Odf/00_preInstall.sh"
oc_create -Rf 00_Install_Odf/01_subscription_odf.yaml
wait_for_subscription odf-operator openshift-storage 900

wait_for_all_csvs openshift-storage 900

oc_create -Rf 00_Install_Odf/02_storagecluster.yaml
run_script "00_Install_Odf/03_postInstall.sh"   # polls until Ceph is HEALTH_OK

# ── Phase 2: Operators ────────────────────────────────────────────────────────
log "--- Phase 2: Install Operators ---"
oc_create -Rf 01_Operators/
wait_for_subscription coo-operator           openshift-operators             600
wait_for_subscription loki-operator          openshift-operators-redhat      600
wait_for_subscription logging-operator       openshift-logging               600
wait_for_subscription otel-operator          openshift-operators             600
wait_for_subscription tempo-operator         openshift-operators             600

# ── Phase 3: Test App ─────────────────────────────────────────────────────────
log "--- Phase 3: Deploy Test App ---"
oc_create -Rf 02_App/

# ── Phase 4: Logging ──────────────────────────────────────────────────────────
log "--- Phase 4: Configure Logging ---"
run_script "03_Logging/01_commands.sh"
oc_create -f 03_Logging/02_objectclaim.yaml
run_script "03_Logging/03_bucketsecret.sh"
oc_create -f 03_Logging/04_loggingstack.yaml
oc_create -f 03_Logging/05_alertingrule.yaml

# ── Phase 5: OpenTelemetry ────────────────────────────────────────────────────
log "--- Phase 5: Configure OpenTelemetry ---"
oc_create -f 04_Opentelemetry/01_collector.yaml

# ── Phase 6: Tempo ────────────────────────────────────────────────────────────
log "--- Phase 6: Configure Tempo ---"
oc_create -f 05_Tempo/01_objectclaim.yaml
run_script "05_Tempo/02_bucketsecret.sh"
oc_create -f 05_Tempo/03_tempo.yaml
oc_create -f 05_Tempo/04_uiplugin.yaml

# ── Phase 7: User Workload Monitoring ─────────────────────────────────────────
log "--- Phase 7: Configure User Workload Monitoring ---"
oc_create -Rf 06_UserWorkload/

# ── Phase 8: Deploy OTEL sidecar ─────────────────────────────────────────

oc scale -n ns1-uwl --replicas=0 deployment/threepilar-uwl-example-app
oc scale -n ns1-uwl --replicas=1 deployment/threepilar-uwl-example-app

log "=== Deployment complete ==="
