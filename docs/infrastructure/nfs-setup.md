# 🗂️ Configuration NFS

Configuration du serveur NFS pour le stockage partagé.

## Script d'installation NFS

Sur le master :

```bash
mkdir script
cd script
nano install-nfs.sh
```

Contenu du fichier `install-nfs.sh` :

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

## Exécution

```bash
chmod +x install-nfs.sh
./install-nfs.sh
```

## Vérification

```bash
sudo exportfs -v
```
