# 🏗️ Configuration Vagrant et Kubernetes

Configuration des VMs et du cluster Kubernetes.

## 📋 Setup initial

### 1. Configuration du Vagrantfile

```bash
cd vagrant/
cp Vagrantfile.sample Vagrantfile
```

**Personnalisez votre configuration** dans `Vagrantfile` :

- Ajustez `MEMORY` et `CPUS` selon vos ressources
- Modifiez les IPs si nécessaire (réseau 192.168.56.x)
- Adaptez les ports forwarding selon vos besoins

### 2. Fichiers

- `Vagrantfile.sample` - Template de configuration (à ne pas modifier)
- `Vagrantfile` - Votre configuration locale (ignorée par Git)

> **Note** : Le fichier `Vagrantfile` est dans `.gitignore` pour permettre des configurations personnalisées. Chaque développeur peut adapter sa configuration locale sans impacter les autres.

## Prérequis

- Vagrant 2.4.3+
- VirtualBox 7.1.6+

## Installation

```bash
cd vagrant/
vagrant up
```

## Configuration master

```bash
vagrant ssh master
```

Puis :

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config
```

## Installation des outils

### Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

### K9S

```bash
curl -LO https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz
tar -xvf k9s_Linux_amd64.tar.gz
sudo mv k9s /usr/local/bin/
```

### Alias utiles

```bash
echo "alias k='kubectl'" >> ~/.bashrc && echo "alias h='helm'" >> ~/.bashrc && source ~/.bashrc
```

## Vérification

```bash
kubectl get nodes
```

Devrait afficher les 3 nœuds Ready.
