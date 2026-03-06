 The response should be in Italian.

Obbiettivo del progetto. 

è quello di installare nuvolaris con un comando ops cloud aruba-kaas create 

l'attività è quella di prendere il comando ops cloud k3 create e rimuovere la parte dove avviene il setup di k3s tramite connessione ssh. Dal momento che k3s è già installato e provisionato da Aruba è necessario soltanto connettersi al cluster ed effettuare tutti gli step successivi. 

Come da specifiche globali nel file config.toml, il file agent.md è stato aggiornato in questa folder tenendo tracciate tutte le modifiche effettuate dall'agente AI. Le modifiche principali includono:

1. Creazione del comando ops cloud aruba-kaas create basato sull'implementazione k3s
2. Rimozione della parte di setup k3s tramite SSH poiché k3s è già installato e provisionato da Aruba
4. Mantenimento dell'installazione di cert-manager e degli altri passi per la configurazione di nuvolaris

5. aggiunta di un nuovo task chiamato deploy che esegua i comandi che sono nel file di esempio script installazione esempio e accetti come parametro in input l'apihost 

6. aggiunta di un nuovo task chiamato connect dove passiamo il file kubeconfig e viene fatta una prova di connnesione al cluster e vengono mostrati lo stato dei nodi e la versione. 

7. aggiunta di un nuovo task che permette tramite Aruba api di fare provisioning del'elastic ip da aggangiare al cluster per pubblicare all'esterno il servizio e usare KAAS_API_KEY per autenticarsi

8. aggiungere prima della installazione di nuvolaris i sequenti comandi 

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install \
ingress-nginx ingress-nginx/ingress-nginx \
--set controller.ingressClassResource.default=true \
--namespace ingress-nginx \
--create-namespace

kubectl get service --namespace ingress-nginx ingress-nginx-controller --output wide

9. creare uno script che permette l'installazione di nuvolaris con i seguenti step: 

    A. installazione ingress-nginx
    B. installazione cert-manager
    C. esecuzione in parallello:  della patch di mongodb e dell'installazione di nuvolaris. quando il pod mongodb è pronto, si fa patch e cancellazione del pod per prendere le modifiche. 
    D. configurazione ingress nginx LoadBalancer Aruba se necessario

REGOLE:

10. aggiornare sempre readme.md con le istruzioni per l'installazione e l'utilizzo del tool
11. aggiornare un file agent.md in questa folder con il log delle attività dell'agente AI.
12. aggiungere alle specifiche nuove specifiche impartire tramite chat. 
    


