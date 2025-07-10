## Déploiement des applications avec ArgoCD
# # ArgoCD est un outil de déploiement continu basé sur GitOps pour Kubernetes.  
# Il permet de gérer les applications Kubernetes en utilisant des dépôts Git comme source de vérité.

prérequis :
# - Avoir un cluster Kubernetes opérationnel
# - Avoir installé ArgoCD dans le namespace `argocd`
# - Avoir un dépôt Git privé contenant les manifests Kubernetes ou les charts Helm
# - Avoir accès à la machine `master` (ex: VM Vagrant)

sur MASTER faire la commande suivante avant de déployer l'application :
```bash
kubectl create namespace log
kubectl create namespace security
```


toujours sur master faire la commande suivante pour créer le nfs :
```bash
mkdir script
cd script
nano install-nfs.sh
```

dans le fichier `install-nfs.sh`, ajoute le contenu suivant :
```bash
# Installer le serveur NFS
sudo apt update
sudo apt install -y nfs-kernel-server

# Créer le répertoire à partager
sudo mkdir -p /srv/nfs/k8s-data
sudo chown -R nobody:nogroup /srv/nfs/k8s-data
sudo chmod 777 /srv/nfs/k8s-data

# Éditer le fichier /etc/exports
echo "/srv/nfs/k8s-data *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports

# Appliquer la configuration
sudo exportfs -rav

# Démarrer le serveur NFS
sudo systemctl enable --now nfs-server

# Vérifier que le NFS est bien exporté
sudo exportfs -v
```

puis rendre le script exécutable et l'exécuter :
```bash
chmod +x install-nfs.sh
./install-nfs.sh
```


ajouter les crd pour Prometheus et Grafana :
```bash
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
```

ensuite depuis argoCD, créer l'application avec les paramètres suivants :
- Clique sur **"NEW APP"**
- Renseigne :
  - `Application Name` : `root-app`
  - `Project` : `default`
  - `Repository URL` : ton URL Git
  - `Revision` : `HEAD` (ou une branche précise)
  - `Path` : `kube/apps`
  - `Cluster URL` : `https://kubernetes.default.svc`
  - `Namespace` : `default`
