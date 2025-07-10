#!/bin/bash
set -e

echo "Installation de Kubernetes sur le master..."

# Désactivation du swap (nécessaire pour Kubernetes)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Mise à jour des paquets et installation des prérequis
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

# Téléchargement et installation de kubectl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Ajout de la clé GPG de Kubernetes
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Ajout du dépôt Kubernetes
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Installation de kubelet, kubeadm et kubectl
sudo apt update -y
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Installation de containerd (runtime pour Kubernetes)
sudo apt update -y
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Modification du fichier containerd pour activer SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Redémarrage et activation du service containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Activation du transfert IP (pour satisfaire les prérequis de Kubernetes)
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-ipforward.conf
sudo sysctl --system

# Initialisation du cluster
echo "[INFO] Initialisation du cluster Kubernetes..."
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# Configuration de kubectl pour l'utilisateur vagrant
echo "[INFO] Configuration de kubectl pour vagrant..."
mkdir -p /home/vagrant/.kube
sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config
echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc

# Application du plugin réseau Calico
echo "[INFO] Installation de Calico..."
sudo -u vagrant KUBECONFIG=/home/vagrant/.kube/config kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml

# Génération de la commande join pour les workers
echo "[INFO] Génération de la commande kubeadm join..."
sudo kubeadm token create --print-join-command > /vagrant/kubeadm-join-command.sh
chmod +x /vagrant/kubeadm-join-command.sh

echo "✅ Kubernetes Master installé avec succès."
echo "➡️  Commande join enregistrée dans /vagrant/kubeadm-join-command.sh"

# --------------------------------------------------
# [INFO] Installation et configuration du serveur NFS
# --------------------------------------------------
echo "[INFO] Installation du serveur NFS sur le master..."
sudo apt install -y nfs-kernel-server

echo "[INFO] Création du dossier partagé NFS..."
sudo mkdir -p /srv/nfs/k8s-data
sudo chmod 777 /srv/nfs/k8s-data

echo "[INFO] Configuration de l'export NFS..."
echo "/srv/nfs/k8s-data *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee /etc/exports

echo "[INFO] Redémarrage du service NFS..."
sudo exportfs -rav
sudo systemctl enable nfs-server
sudo systemctl restart nfs-server

echo "✅ Serveur NFS installé et configuré avec succès."
