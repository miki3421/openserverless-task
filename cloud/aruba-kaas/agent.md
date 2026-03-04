# Agent Log - Aruba KaaS Implementation

## Task Summary
- Allineato `ops cloud aruba-kaas` alla specifica Aruba KaaS partendo da `k3s`
- Rimossa tutta la parte di provisioning/installazione k3s via SSH
- Implementata importazione del cluster tramite kubeconfig passato da file
- Mantenuta installazione di cert-manager nel flusso `create`
- Aggiunto task `deploy` che esegue i passi del file di esempio con `apihost` in input

## Modifiche Applicate
1. `create` ora richiede `<kubeconfig>`, importa il file locale e installa cert-manager
2. `kubeconfig` ora importa il file locale invece di recuperarlo via SSH
3. `delete` rimuove solo i kubeconfig locali importati
4. `deploy` esegue:
   - `ops config slim`
   - `ops config volumes ...` con i valori dello script di esempio
   - `ops config apihost <apihost> --protocol=https --tls:test@nuvolaris.org`
   - `ops setup cluster`
5. Aggiornata `docopts.md` con nuova CLI coerente: `create <kubeconfig>` e `deploy <apihost>`

## Note
- `OPERATOR_CONFIG_KUBE` resta impostato a `k3s` per coerenza con l'ambiente Aruba KaaS pre-provisionato.
