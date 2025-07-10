#!/bin/bash
set -e

echo "=================================================="
echo "Installation de Kubernetes sur le master..."
echo "=================================================="

echo "--------------------------------------------------"
echo "[DEBUG] Désactivation du swap..."
echo "--------------------------------------------------"
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "--------------------------------------------------"
echo "[DEBUG] Mise à jour des paquets et installation des prérequis..."
echo "--------------------------------------------------"
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg build-essential procps file git

echo "--------------------------------------------------"
echo "[DEBUG] Ajout de la clé GPG et du dépôt Kubernetes..."
echo "--------------------------------------------------"
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key \
  | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "--------------------------------------------------"
echo "[DEBUG] Installation des outils Kubernetes (kubelet, kubeadm, kubectl)..."
echo "--------------------------------------------------"
sudo apt update -y
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "--------------------------------------------------"
echo "[DEBUG] Installation et configuration du runtime containerd..."
echo "--------------------------------------------------"
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "--------------------------------------------------"
echo "[DEBUG] Activation du transfert d'IP..."
echo "--------------------------------------------------"
sudo sysctl -w net.ipv4.ip_forward=1

echo "--------------------------------------------------"
echo "[DEBUG] Initialisation du cluster Kubernetes..."
echo "--------------------------------------------------"
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=192.168.56.10

echo "--------------------------------------------------"
echo "[DEBUG] Configuration de kubectl pour l'utilisateur courant..."
echo "--------------------------------------------------"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "--------------------------------------------------"
echo "[DEBUG] Installation du plugin réseau Calico..."
echo "--------------------------------------------------"
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml

echo "--------------------------------------------------"
echo "[DEBUG] Accés aux commandes du cluster..."
echo "--------------------------------------------------"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config

# --- Install NFS Server for dynamic PV ---
echo "[INFO] Installing NFS server on master node..."

sudo apt update
sudo apt install -y nfs-kernel-server

# Créer le dossier pour les volumes Kubernetes
sudo mkdir -p /srv/nfs/k8s-data
sudo chown nobody:nogroup /srv/nfs/k8s-data
sudo chmod 777 /srv/nfs/k8s-data

# Configurer l'export
echo "/srv/nfs/k8s-data *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee /etc/exports

# Redémarrer les services
sudo exportfs -rav
sudo systemctl restart nfs-kernel-server

echo "[INFO] NFS server setup done!"

echo "--------------------------------------------------"
echo "[DEBUG] Génération et stockage de la commande join pour les workers..."
echo "--------------------------------------------------"
sudo kubeadm token create --print-join-command > /vagrant/kubeadm-join-command.sh
chmod +x /vagrant/kubeadm-join-command.sh

echo "=================================================="
echo "Installation terminée : Kubernetes Master et K9S installés avec succès."
echo "--------------------------------------------------"
echo "Récupérez la commande pour ajouter un worker dans /vagrant/kubeadm-join-command.sh"
echo "=================================================="
