# Aruba KaaS

## Installazione e utilizzo

Prerequisiti:
- `kubectl`, `helm`, `curl`, `jq`
- kubeconfig Aruba KaaS valido
- CLI `ops` configurata nel progetto

Flusso consigliato:
1. `ops cloud aruba-kaas connect <kubeconfig>`
2. `ops cloud aruba-kaas create <kubeconfig>`
3. `ops cloud aruba-kaas deploy <apihost>`

Nota operativa: i task Aruba KaaS usano `ensure-kubeconfig`, quindi se non hai eseguito `create` nella sessione corrente viene usato automaticamente `KUBECONFIG` (o fallback `~/.kube/config`).

`deploy` esegue lo script `cloud/aruba-kaas/install-nuvolaris.sh` con questi step:
1. installazione/upgrade `ingress-nginx`
   - include `controller.ingressClassResource.default=true`
   - include `controller.progressDeadlineSeconds=600` per compatibilita cluster
2. configurazione **obbligatoria** Aruba LB come interconnessione tra pubblico e ingress interno (task `create-lb` su `ingress-nginx/ingress-nginx-controller`, senza provisioning automatico EIP)
3. installazione `cert-manager`
4. configurazione Nuvolaris (`config slim`, `config volumes`, `config apihost`) e `ops setup cluster`
5. patch MongoDB in parallelo al setup (attende pod pronto, applica `mongodb-fix-fsgroup.yaml`, riavvia pod)
6. configurazione opzionale del LoadBalancer ingress Aruba con:
   - `KAAS_INGRESS_LB_ADDRESS`
   - `KAAS_INGRESS_LB_ID`

Comandi utili:
- `ops cloud aruba-kaas elastic-ip` provisioning/attach Elastic IP via Aruba API (opzionale/manuale)
- `ops cloud aruba-kaas fix-mongodb-permissions` riapplica patch permessi MongoDB
- `ops cloud aruba-kaas create-lb <namespace> <deployment> <service>` espone un deployment come LoadBalancer
  - se il Service esiste gia, applica una patch non distruttiva (non forza delete/recreate del LB)
- `ops cloud aruba-kaas status` stato nodi cluster
- `ops cloud aruba-kaas info` contesto corrente

## Flusso chiamate verso `85.235.141.133`

```mermaid
flowchart TD
    A[Client / Browser / API Consumer] --> B[DNS nip.io<br/>*.85.235.141.133.nip.io]
    B --> C[OpenStack LoadBalancer VIP<br/>85.235.141.133]
    C --> D[K8s Service nuvolaris/controller<br/>Type: LoadBalancer<br/>80/443 -> targetPort 8080]
    D --> E[Pods app=controller]

    E --> F1[Ingress: 85.235.141.133.nip.io/api/v1|/api/info|/api/my]
    E --> F2[Ingress: 85.235.141.133.nip.io/(.*)]
    E --> F3[Ingress: www.85.235.141.133.nip.io]
    E --> F4[Ingress: s3.85.235.141.133.nip.io]

    F1 --> G1[Service controller:3233]
    F2 --> G2[Service nuvolaris-static-svc:8080]
    F3 --> G3[Service controller:3233 or nuvolaris-static-svc:8080]
    F4 --> G4[Service seaweedfs:9000]
```

### Routing sintetico

| Host | Path | Backend service |
|---|---|---|
| `85.235.141.133.nip.io` | `/api/v1`, `/api/info`, `/api/my` | `controller:3233` |
| `85.235.141.133.nip.io` | `/(.*)` | `nuvolaris-static-svc:8080` |
| `www.85.235.141.133.nip.io` | `/api/my` | `controller:3233` |
| `www.85.235.141.133.nip.io` | `/(.*)` | `nuvolaris-static-svc:8080` |
| `s3.85.235.141.133.nip.io` | `/` | `seaweedfs:9000` |

Nota: sono presenti anche ingress temporanei `cm-acme-http-solver-*` per challenge ACME (`/.well-known/acme-challenge/...`).
