# 🚀 Installation ArgoCD

Installation et configuration d'ArgoCD pour le déploiement GitOps.

## Prérequis

- Cluster Kubernetes fonctionnel
- Projet Git privé
- kubectl installé

## Installation

### 1. Créer le namespace

```bash
kubectl create namespace argocd
```

### 2. Installer Argo CD

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 3. Générer une clé SSH

```bash
ssh-keygen -t rsa -b 4096 -f /tmp/argocd-deploy-key -N ""
cat /tmp/argocd-deploy-key.pub
```

- Copier la clé publique affichée
- Aller dans GitHub → repo → Settings → Deploy keys
- Ajouter la clé et cocher "Allow write access"

### 4. Créer le secret pour le dépôt

Créer `repo-secret.yaml` :

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-private-repo-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repo-creds
type: Opaque
stringData:
  url: "git@github.com:Jehuty12/T-CLO-902-PRIVEE.git"
  sshPrivateKey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    [VOTRE_CLE_PRIVEE_ICI]
    -----END OPENSSH PRIVATE KEY-----
```

Appliquer :

```bash
kubectl apply -f repo-secret.yaml
```

## Accès à l'interface

### 1. Exposer le service

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```

### 2. Récupérer le port

```bash
kubectl get svc argocd-server -n argocd
```

### 3. Récupérer le mot de passe

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 4. Se connecter

URL : `http://192.168.56.10:31234`
- Login : `admin`
- Mot de passe : celui récupéré à l'étape 3

## Configuration HTTPS (optionnel)

### 1. Générer le certificat

```bash
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout argocd.key \
  -out argocd.crt \
  -subj "/CN=argocd.client"
```

### 2. Créer le secret TLS

```bash
kubectl create secret tls argocd-tls \
  --cert=argocd.crt \
  --key=argocd.key \
  -n argocd
```

### 3. Configurer le fichier hosts

Ajouter dans `/etc/hosts` :

```text
192.168.56.10 argocd.client
```

Accès : `https://argocd.client:31234`
