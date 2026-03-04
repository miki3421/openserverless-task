# Agent Log - Aruba KaaS Implementation

## Task Summary
- Allineato `ops cloud aruba-kaas` alla specifica Aruba KaaS partendo da `k3s`
- Rimossa tutta la parte di provisioning/installazione k3s via SSH
- Implementata importazione del cluster tramite kubeconfig passato da file
- Mantenuta installazione di cert-manager nel flusso `create`
- Aggiunto task `deploy` che esegue i passi del file di esempio con `apihost` in input
- Aggiunto task `connect` che importa kubeconfig, testa la connessione e mostra nodi/versione

## Modifiche Applicate
1. `create` ora richiede `<kubeconfig>`, esegue `connect` e installa cert-manager
2. `kubeconfig` ora importa il file locale invece di recuperarlo via SSH
3. `delete` rimuove solo i kubeconfig locali importati
4. `deploy` esegue:
   - `ops config slim`
   - `ops config volumes ...` con i valori dello script di esempio
   - `ops config apihost <apihost> --protocol=https --tls:test@nuvolaris.org`
   - `ops setup cluster`
5. `connect` accetta `<kubeconfig>`, importa la configurazione e mostra:
   - `kubectl get nodes`
   - `kubectl version`
6. Aggiornata `docopts.md` con nuova CLI coerente: `connect <kubeconfig>`, `create <kubeconfig>` e `deploy <apihost>`
7. Corretto il task `deploy` per compatibilità parser YAML (`cmd` con `:` spostato in blocco multilinea)
8. Migliorato `copy-kubeconfig`: ora accetta sia path assoluto sia nome file presente in `~/.kube`

## Note
- `OPERATOR_CONFIG_KUBE` resta impostato a `k3s` per coerenza con l'ambiente Aruba KaaS pre-provisionato.
