✅ Étape 1 : Génère le certificat TLS (si ce n’est pas déjà fait)

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=*.client/O=client"
```
✅ Étape 2 : Injecte le secret dans le cluster

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
applique ensuite le certificat dans t'es autres namespaces (par exemple `frontend` et `backend`) :
```bash
# Exemple pour le namespace app
kubectl get secret traefik-cert -n traefik -o yaml \
  | sed 's/namespace: traefik/namespace: app/' \
  | kubectl apply -f -
```
➡️ Répète pour :

```bash
sed 's/namespace: traefik/namespace: argocd/' | kubectl apply -f -
sed 's/namespace: traefik/namespace: log/' | kubectl apply -f -
sed 's/namespace: traefik/namespace: security/' | kubectl apply -f -
```

🧩 common-values.yaml de traefik à mettre à jour (complet et fonctionnel)
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

#   certificatesResolvers:
#     letsencrypt:
#       acme:
#         email: ton.email@domaine.fr
#         storage: /data/acme.json
#         httpChallenge:
#           entryPoint: web

# ⚠️ Doit rester à la racine
ingressRoute:
  dashboard:
    enabled: true
    host: traefik.client
    annotations:
      traefik.ingress.kubernetes.io/router.entrypoints: web
    matchRule: Host(`traefik.client`)
    entryPoints: ["web"]
```
🔁 Ce fichier n’injecte pas de secret TLS via extraDeploy car tu l’as déjà créé manuellement.

🌐 frontend-ingress.yaml corrigé avec HTTPS (TLS via websecure)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    # traefik.ingress.kubernetes.io/router.middlewares: security-oauth2-proxy@kubernetescrd
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
                  number: {{ .Values.image.frontend.port }}
  tls:
    - hosts:
        - frontend.client
      secretName: traefik-cert
```
🔐 Le certificat sera utilisé grâce au secretName: traefik-cert.

🖥️ Étape 3 : Ajoute les entrées dans le fichier hosts Windows
Ouvre le fichier `C:\Windows\System32\drivers\etc\hosts` avec un éditeur de texte en mode administrateur.
Ajoute :
```plaintext
192.168.56.102 frontend.client
192.168.56.102 backend.client
192.168.56.102 argocd.client
192.168.56.102 grafana.client
```
✅ L’adresse 192.168.56.102 est bien l’IP EXTERNAL-IP exposée par Traefik (kubectl get svc -n traefik).

🚀 Étape 4 : Commit, Push & Synchronise ArgoCD
Commit tes changements puis dans ArgoCD, synchronise le projet `root-app` ou `frontend-app` si c’est un appOfApps.

🧪 Étape 5 : Tester
Accède à :

https://frontend.client

Le navigateur affichera une alerte de certificat auto-signé → clique sur "Continuer".

Tu devrais voir l’application frontend s’afficher.

Il ne te reste plus qu’à faire de même pour le backend et les autres applications ( créer les ingress et mettre à jour les fichiers hosts si nécessaire ).