# Configuration Prometheus

## Installation et configuration Prometheus

### Étape 1 : Vérification des CRDs

Vérifier les CRDs présentes pour prometheus :

```bash
kubectl get crds | grep monitoring.coreos.com
```

Tu devrais voir une sortie similaire à ceci si les CRDs sont bien installés :

```bash
alertmanagers.monitoring.coreos.com
podmonitors.monitoring.coreos.com
prometheuses.monitoring.coreos.com
prometheusrules.monitoring.coreos.com
servicemonitors.monitoring.coreos.com
thanosrulers.monitoring.coreos.com
```

### Étape 2 : Installation des CRDs manquants

Si tu ne vois pas ces CRDs, tu peux les installer avec la commande suivante :

```bash
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
```

### Étape 3 : Configuration Prometheus

Ajoute un fichier `prometheus.yaml` dans ton chart Helm Prometheus (`kube/charts/prometheus/templates/prometheus.yaml`) avec le contenu suivant :

```yaml
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: prometheus
  namespace: log
spec:
  replicas: 1
  serviceAccountName: prometheus-server
  serviceMonitorSelector:
    matchLabels:
      release: prometheus
  serviceMonitorNamespaceSelector:
    matchExpressions:
      - key: kubernetes.io/metadata.name
        operator: In
        values:
          - app
          - log
          - metallb-system
  resources:
    requests:
      memory: 400Mi
      cpu: 200m
```

### Étape 4 : Déploiement

Applique la configuration en synchronisant avec ArgoCD.

### Étape 5 : Vérification

Accède à l'interface web de Prometheus et vérifie que les métriques sont bien collectées dans l'onglet "Status/Targets".
