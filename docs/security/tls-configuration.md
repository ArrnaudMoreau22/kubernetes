# Configuration TLS et HTTPS

## Étape 1 : Génération du certificat TLS

Génère le certificat TLS :

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=*.client/O=client"
```

## Étape 2 : Injection du secret dans le cluster

Crée le secret dans le namespace traefik :

```bash
kubectl create secret tls traefik-cert \
  --cert=tls.crt \
  --key=tls.key \
  -n traefik
```

Vérifie :

```bash
kubectl get secret traefik-cert -n traefik
```

Applique le certificat dans les autres namespaces :

```bash
# Exemple pour le namespace app
kubectl get secret traefik-cert -n traefik -o yaml \
  | sed 's/namespace: traefik/namespace: app/' \
  | kubectl apply -f -
```

Répète pour les autres namespaces :

```bash
kubectl get secret traefik-cert -n traefik -o yaml \
  | sed 's/namespace: traefik/namespace: argocd/' \
  | kubectl apply -f -

kubectl get secret traefik-cert -n traefik -o yaml \
  | sed 's/namespace: traefik/namespace: log/' \
  | kubectl apply -f -

kubectl get secret traefik-cert -n traefik -o yaml \
  | sed 's/namespace: traefik/namespace: security/' \
  | kubectl apply -f -
```

## Étape 3 : Configuration Traefik

Mise à jour du fichier `common-values.yaml` de traefik :

```yaml
traefik:
  logs:
    general:
      level: DEBUG

  persistence:
    enabled: true
    path: /data
    accessMode: ReadWriteOnce
    size: 1Gi

  ports:
    web:
      port: 8000
      nodePort: 30080
      expose:
        default: true
      protocol: TCP

    websecure:
      port: 8443
      nodePort: 30443
      expose:
        default: true
      protocol: TCP

    traefik:
      port: 8080
      nodePort: 30088
      expose:
        default: true
      protocol: TCP

    metrics:
      port: 9100
      nodePort: 30090
      expose:
        default: false
      protocol: TCP

  service:
    type: LoadBalancer

  additionalArguments:
    - "--api.insecure=true"
    - "--api.dashboard=true"
    - "--entrypoints.web.address=:8000"
    - "--entrypoints.websecure.address=:8443"
    - "--entrypoints.traefik.address=:8080"
    - "--entrypoints.metrics.address=:9100/tcp"
    - "--ping.entrypoint=traefik"
    - "--metrics.prometheus=true"
    - "--metrics.prometheus.entrypoint=metrics"
    - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
    - "--entrypoints.web.http.redirections.entrypoint.scheme=https"

  providers:
    kubernetesCRD:
      enabled: true
    kubernetesIngress:
      enabled: true

  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 1000

  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 100m
      memory: 128Mi

ingressRoute:
  dashboard:
    enabled: true
    host: traefik.client
    annotations:
      traefik.ingress.kubernetes.io/router.entrypoints: web
    matchRule: Host(`traefik.client`)
    entryPoints: ["web"]
```

## Étape 4 : Configuration des ingress

Exemple d'ingress pour le frontend avec HTTPS :

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  ingressClassName: traefik
  rules:
    - host: frontend.client
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 80
  tls:
    - hosts:
        - frontend.client
      secretName: traefik-cert
```

## Étape 5 : Configuration du fichier hosts

Ajoute les entrées dans le fichier hosts Windows (`C:\Windows\System32\drivers\etc\hosts`) :

```plaintext
192.168.56.102 frontend.client
192.168.56.102 backend.client
192.168.56.102 argocd.client
192.168.56.102 grafana.client
```

> L'adresse 192.168.56.102 est l'IP EXTERNAL-IP exposée par Traefik (`kubectl get svc -n traefik`).

## Étape 6 : Déploiement

Commit tes changements puis dans ArgoCD, synchronise le projet `root-app`.

## Étape 7 : Test

Accède à :

```bash
https://frontend.client
```

Le navigateur affichera une alerte de certificat auto-signé → clique sur "Continuer".

Tu devrais voir l'application frontend s'afficher.


