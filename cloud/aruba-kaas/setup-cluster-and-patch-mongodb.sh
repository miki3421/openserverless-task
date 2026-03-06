#!/bin/sh
set -eu

OPS_CMD="${1:-}"
KUBECONFIG_PATH="${2:-}"
TIMEOUT_SECONDS="${MONGO_PATCH_TIMEOUT_SECONDS:-1800}"

if [ -z "$OPS_CMD" ]; then
  echo "[aruba-kaas][mongodb-fix] errore: comando ops mancante"
  exit 1
fi
if [ -z "$KUBECONFIG_PATH" ]; then
  echo "[aruba-kaas][mongodb-fix] errore: kubeconfig mancante"
  exit 1
fi

(
  START_TS=$(date +%s)
  while :; do
    NOW_TS=$(date +%s)
    if [ $((NOW_TS - START_TS)) -ge "$TIMEOUT_SECONDS" ]; then
      echo "[aruba-kaas][mongodb-fix] WARN: statefulset nuvolaris-mongodb non trovato entro ${TIMEOUT_SECONDS}s." >&2
      exit 0
    fi

    if kubectl --kubeconfig "$KUBECONFIG_PATH" -n nuvolaris get statefulset nuvolaris-mongodb >/dev/null 2>&1; then
      PATCH_DONE="$(kubectl --kubeconfig "$KUBECONFIG_PATH" -n nuvolaris get statefulset nuvolaris-mongodb -o jsonpath='{.metadata.annotations.nuvolaris\.org/fsgroup-patched}' 2>/dev/null || true)"
      if [ "$PATCH_DONE" != "true" ]; then
        kubectl --kubeconfig "$KUBECONFIG_PATH" -n nuvolaris patch statefulset nuvolaris-mongodb \
          --type=merge \
          -p '{"spec":{"template":{"spec":{"securityContext":{"fsGroup":1001}}}}}'
        kubectl --kubeconfig "$KUBECONFIG_PATH" -n nuvolaris annotate statefulset nuvolaris-mongodb \
          nuvolaris.org/fsgroup-patched=true \
          --overwrite
        kubectl --kubeconfig "$KUBECONFIG_PATH" -n nuvolaris delete pod nuvolaris-mongodb-0 \
          --ignore-not-found=true \
          --wait=false || true
      fi
      exit 0
    fi
    sleep 2
  done
) &
PATCH_WATCHER_PID="$!"

SETUP_RC=0
"$OPS_CMD" setup cluster || SETUP_RC=$?
wait "$PATCH_WATCHER_PID" || true

if [ "$SETUP_RC" -ne 0 ]; then
  echo "[aruba-kaas][mongodb-fix] errore setup cluster: rc=$SETUP_RC"
  exit "$SETUP_RC"
fi
