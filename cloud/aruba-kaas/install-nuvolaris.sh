#!/bin/sh
set -eu

APIHOST="${1:-${OPERATOR_CONFIG_APIHOST:-}}"
if [ -z "$APIHOST" ]; then
  echo "required <apihost> (oppure imposta OPERATOR_CONFIG_APIHOST)"
  exit 1
fi

if [ -z "${OPS_TMP:-}" ]; then
  echo "OPS_TMP non impostata"
  exit 1
fi

KUBECONFIG_PATH="$OPS_TMP/kubeconfig"
if [ ! -f "$KUBECONFIG_PATH" ]; then
  echo "cluster non configurato: esegui prima 'ops cloud aruba-kaas create <kubeconfig>'"
  exit 1
fi

if [ -z "${OPS:-}" ]; then
  echo "OPS command non disponibile"
  exit 1
fi

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
CERT_MANAGER_URL="${CERT_MANAGER_URL:-https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml}"
CERT_MANAGER_MANIFEST="$SCRIPT_DIR/cert-manager.yaml"

echo "[aruba-kaas][install] Step A: installazione ingress-nginx"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo update
helm upgrade --install \
  ingress-nginx ingress-nginx/ingress-nginx \
  --set controller.ingressClassResource.default=true \
  --set controller.progressDeadlineSeconds=600 \
  --namespace ingress-nginx \
  --create-namespace \
  --kubeconfig "$KUBECONFIG_PATH"
kubectl --kubeconfig "$KUBECONFIG_PATH" get service --namespace ingress-nginx ingress-nginx-controller --output wide

echo "[aruba-kaas][install] Step B: configurazione Aruba LB per interconnessione pubblico->ingress interno"
task --taskfile "$SCRIPT_DIR/opsfile.yml" create-lb \
  _namespace_=ingress-nginx \
  _deployment_=ingress-nginx-controller \
  _service_=ingress-nginx-controller

echo "[aruba-kaas][install] Step C: installazione cert-manager"
if [ ! -f "$CERT_MANAGER_MANIFEST" ]; then
  curl -fsSL "$CERT_MANAGER_URL" -o "$CERT_MANAGER_MANIFEST"
fi
kubectl --kubeconfig "$KUBECONFIG_PATH" apply -f "$CERT_MANAGER_MANIFEST"

echo "[aruba-kaas][install] Configurazione Nuvolaris"
"$OPS" config slim
"$OPS" config volumes \
  --couchdb=10 \
  --redisvol=5 \
  --storage=50 \
  --pgvol=10 \
  --mongodbvol=10 \
  --etcdvol=10 \
  --mvvol=10 \
  --seaweedfsvol=10 \
  --kafka=10 \
  --zookeeper=5 \
  --mvzookvol=5 \
  --pulsarjournalvol=5 \
  --pulsarledgelvol=5 \
  --alerting=5
task --taskfile "$SCRIPT_DIR/opsfile.yml" preflight-ingress
"$OPS" config apihost "$APIHOST" --protocol=https --tls=test@nuvolaris.org


echo "[aruba-kaas][install] Step D: setup cluster e patch mongodb in parallelo"
"$SCRIPT_DIR/setup-cluster-and-patch-mongodb.sh" "$OPS" "$KUBECONFIG_PATH"

echo "[aruba-kaas][install] Step E: configurazione Aruba LB su ingress-nginx se necessario (opzionale)"
if [ -n "${KAAS_INGRESS_LB_ADDRESS:-}" ]; then
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n ingress-nginx annotate svc ingress-nginx-controller \
    loadbalancer.openstack.org/load-balancer-address="$KAAS_INGRESS_LB_ADDRESS" \
    --overwrite
fi
if [ -n "${KAAS_INGRESS_LB_ID:-}" ]; then
  kubectl --kubeconfig "$KUBECONFIG_PATH" -n ingress-nginx annotate svc ingress-nginx-controller \
    loadbalancer.openstack.org/load-balancer-id="$KAAS_INGRESS_LB_ID" \
    --overwrite
fi
kubectl --kubeconfig "$KUBECONFIG_PATH" get svc -n ingress-nginx ingress-nginx-controller -o wide

echo "[aruba-kaas][install] completato"
