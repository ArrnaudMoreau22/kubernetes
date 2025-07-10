#!/bin/bash
set -e

echo "=================================================="
echo "Installation du nœud worker pour Kubernetes..."
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
echo "[INFO] Installation du client NFS..."
sudo apt install -y nfs-common

echo "--------------------------------------------------"
echo "[DEBUG] Ajout de la clé GPG et du dépôt Kubernetes..."
echo "--------------------------------------------------"
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key \
  | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "--------------------------------------------------"
echo "[DEBUG] Installation de kubelet, kubeadm et kubectl..."
echo "--------------------------------------------------"
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "--------------------------------------------------"
echo "[DEBUG] Installation et configuration du runtime containerd..."
echo "--------------------------------------------------"
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "--------------------------------------------------"
echo "[DEBUG] Activation du transfert d'IP..."
echo "--------------------------------------------------"
sudo sysctl -w net.ipv4.ip_forward=1

sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

PRIVATE_IP=$(ip -o -4 addr show eth1 | awk '{print $4}' | cut -d/ -f1)

echo "KUBELET_EXTRA_ARGS=--node-ip=${PRIVATE_IP}" | sudo tee /etc/default/kubelet

sudo systemctl daemon-reload
sudo systemctl restart kubelet


# Récupération de la commande join pour intégrer le worker au cluster
if [ -n "$1" ]; then
  KUBEADM_JOIN_CMD="$1"
  echo "--------------------------------------------------"
  echo "[DEBUG] Utilisation de la commande join passée en paramètre."
  echo "--------------------------------------------------"
elif [ -f /vagrant/kubeadm-join-command.sh ]; then
  KUBEADM_JOIN_CMD=$(cat /vagrant/kubeadm-join-command.sh)
  echo "--------------------------------------------------"
  echo "[DEBUG] Utilisation de la commande join depuis /vagrant/kubeadm-join-command.sh."
  echo "--------------------------------------------------"
else
  echo "[ERROR] Aucune commande join n'a été fournie et le fichier /vagrant/kubeadm-join-command.sh n'existe pas."
  exit 1
fi

echo "--------------------------------------------------"
echo "[DEBUG] Exécution de la commande join :"
echo "$KUBEADM_JOIN_CMD"
echo "--------------------------------------------------"
sudo $KUBEADM_JOIN_CMD

echo "=================================================="
echo "Le nœud worker a été ajouté avec succès au cluster Kubernetes."
echo "=================================================="