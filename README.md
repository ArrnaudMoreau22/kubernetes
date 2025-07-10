# Déploiement d'une Application 3-Tiers sur Kubernetes avec une Approche GitOps

Ce projet démontre la mise en place complète d'une infrastructure et d'un déploiement d'une application web 3-tiers (Frontend, Backend, Base de données) sur un cluster Kubernetes. L'ensemble est provisionné localement avec Vagrant et géré via une approche GitOps robuste avec ArgoCD.

Le but est de simuler un environnement de production en intégrant des briques essentielles telles que le monitoring, la journalisation, la sécurité et le routage avancé.

[](https://www.google.com/search?q=./vagrant/LICENSE)

-----

## 🏛️ Architecture

Ce projet déploie une architecture cloud-native complète, où chaque composant joue un rôle précis pour garantir la robustesse, l'observabilité et la sécurité de l'application.

  * **Infrastructure** : Un cluster Kubernetes à 3 nœuds (1 master, 2 workers) est provisionné localement à l'aide de **Vagrant** et **VirtualBox**. Le réseau est géré avec **Calico**.
  * **Application 3-Tiers** :
    1.  Un **Frontend** en Nginx, servant une interface web statique (HTML/JS/CSS) .
    2.  Un **Backend** en Python (Flask) avec une API RESTful, connecté à une base de données et instrumenté pour l'observabilité .
    3.  Une base de données **MySQL** pour la persistance des données, déployée via un chart Helm Bitnami .
  * **GitOps avec ArgoCD** : Le déploiement de toutes les applications et de leur configuration est entièrement automatisé grâce à **ArgoCD**. Le dépôt Git sert de source de vérité unique, suivant le pattern "App of Apps" .
  * **Routage & Sécurité TLS** : **Traefik** est utilisé comme Ingress Controller pour gérer le trafic entrant. La communication est sécurisée via HTTPS grâce à des certificats TLS auto-générés .
  * **Observabilité (Logs, Métriques, Traces)** :
      * **Prometheus** scrape les métriques de tous les composants (applications, Traefik, MetalLB, etc.) via des `ServiceMonitors` .
      * **Grafana** fournit des tableaux de bord pour visualiser les métriques de Prometheus et les logs de Loki .
      * **Loki** et **Promtail** centralisent les logs de tous les pods du cluster .
      * **Tempo** est configuré pour collecter les traces distribuées du backend .
  * **Authentification & RBAC** : **Keycloak** est déployé pour une future gestion centralisée des identités. Des rôles RBAC Kubernetes (`ClusterRole`, `RoleBinding`) sont définis pour gérer les permissions au sein du cluster .
  * **Stockage et Réseau** :
      * Un **serveur NFS** est provisionné sur le nœud master pour fournir du stockage persistant (`PersistentVolume`) .
      * **MetalLB** est utilisé pour fournir des adresses IP externes aux services de type `LoadBalancer` dans un environnement local .

-----

## ✨ Fonctionnalités Principales

  * **Application Complète** : Une application web fonctionnelle permettant de soumettre et de consulter des messages .
  * **Infrastructure as Code** : Cluster Kubernetes entièrement scriptable et reproductible grâce à Vagrant .
  * **Déploiement GitOps** : L'état du cluster est synchronisé en continu avec le dépôt Git via ArgoCD, assurant des déploiements cohérents et fiables .
  * **Haute Disponibilité & Scalabilité** : Utilisation de `HorizontalPodAutoscaler` (HPA) sur le frontend pour un scaling automatique basé sur l'utilisation CPU .
  * **Configuration centralisée** : Utilisation de charts Helm avec des `values.yaml` et `common-values.yaml` pour une gestion efficace de la configuration .
  * **Sécurité de bout en bout** : Communications sécurisées par TLS/HTTPS du client jusqu'aux services internes .
  * **Observabilité Intégrée** : Une pile complète pour les métriques, logs et traces, permettant une supervision fine de l'état du cluster et des applications.

-----

## 🛠️ Pile Technologique

| Domaine | Outils et Technologies |
| :--- | :--- |
| **Infrastructure & Conteneurisation** | Docker, Kubernetes, Vagrant, VirtualBox |
| **CI/CD & GitOps** | Git, ArgoCD, Helm |
| **Application Backend** | Python, Flask, SQLAlchemy, PyMySQL |
| **Application Frontend** | HTML, CSS, JavaScript, Nginx |
| **Base de Données** | MySQL |
| **Routage & Ingress** | Traefik |
| **Monitoring & Observabilité** | Prometheus , Grafana , Loki , Promtail , Tempo |
| **Sécurité & Accès** | Keycloak , OpenSSL, RBAC |
| **Stockage & Réseau** | NFS , MetalLB |

-----

## 🚀 Guide d'Installation et de Déploiement

Le projet est conçu pour être déployé en suivant un ordre logique. Des guides détaillés sont disponibles dans le dossier `/docs`.

### 1\. Prérequis

  * **Vagrant** (\>= 2.4.3)
  * **VirtualBox** (\>= 7.1.6)

### 2\. Démarrage de l'Infrastructure

1.  **Copiez le `Vagrantfile`** :

    ```bash
    cd vagrant/
    cp Vagrantfile.sample Vagrantfile # 
    ```

    *Adaptez la mémoire et les CPU dans `Vagrantfile` si nécessaire.*

2.  **Lancez les VMs** : Cette commande provisionnera les 3 nœuds, installera Kubernetes, Calico, et configurera le serveur NFS sur le master.

    ```bash
    vagrant up # 
    ```

3.  **Configurez `kubectl`** sur le nœud master :

    ```bash
    vagrant ssh master
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```

### 3\. Déploiement d'ArgoCD

Une fois dans le master, suivez le guide détaillé pour installer et configurer ArgoCD.
➡️ **Voir le guide :** [`docs/deployment/argocd-deployment.md`](https://www.google.com/search?q=./docs/deployment/argocd-deployment.md)

### 4\. Déploiement des Applications via GitOps

Le projet utilise une application "racine" (`root-app`) qui déploie toutes les autres applications (backend, frontend, monitoring, etc.).

1.  Créez les `namespaces` requis :
    ```bash
    kubectl create namespace log
    kubectl create namespace security
    ```
2.  Dans l'interface d'ArgoCD, créez l'application `root-app` en pointant vers le chemin `kube/apps` de ce dépôt. ArgoCD se chargera de déployer tous les composants de manière récursive.

➡️ **Voir le guide :** [`docs/deployment/applications-deployment.md`](https://www.google.com/search?q=./docs/deployment/applications-deployment.md)

### 5\. Configuration TLS et Accès

Pour accéder aux services via des noms de domaine, vous devez configurer le chiffrement TLS et mettre à jour votre fichier `hosts` local.

1.  Générez les certificats et appliquez les secrets TLS comme décrit dans le guide.
2.  Ajoutez les entrées suivantes à votre fichier `hosts` (`C:\Windows\System32\drivers\etc\hosts` sur Windows ou `/etc/hosts` sur Linux/macOS), en remplaçant `192.168.56.102` par l'IP externe de votre service Traefik (`kubectl get svc -n traefik`) :
    ```
    192.168.56.102 frontend.client
    192.168.56.102 traefik.client
    192.168.56.102 grafana.client
    192.168.56.102 prometheus.client
    192.168.56.102 keycloak.client
    ```

➡️ **Voir le guide :** [`docs/security/tls-configuration.md`](https://www.google.com/search?q=./docs/security/tls-configuration.md)

-----

## 🌐 Accéder aux Services

Une fois tout déployé, les services sont accessibles via les URLS suivantes (acceptez le certificat auto-signé) :

  * **Application Frontend** : `https://frontend.client`
  * **Tableau de bord Traefik** : `http://traefik.client` (via redirection depuis `web`)
  * **Tableau de bord Grafana** : `https://grafana.client` (login: `admin`/`admin`)
  * **Interface Prometheus** : `https://prometheus.client`
  * **Interface Keycloak** : `https://keycloak.client`
  * **ArgoCD UI** : `http://<IP_MASTER>:<NodePort_ArgoCD>`

-----

## 🗺️ Pour Aller Plus Loin

Ce projet constitue une base solide. Voici quelques pistes d'amélioration possibles :

  * **Intégration Continue (CI)** : Mettre en place un pipeline (ex: GitHub Actions) pour construire et pousser automatiquement les images Docker du frontend et du backend.
  * **Tests Automatisés** : Ajouter des tests unitaires pour le backend Flask et des tests d'intégration pour l'ensemble de l'application.
  * **Sécurité Avancée** : Intégrer pleinement Keycloak à l'application pour l'authentification des utilisateurs, et mettre en place des NetworkPolicies plus strictes.
  * **Déploiement Cloud** : Adapter le projet pour un déploiement sur un fournisseur cloud (AWS, GCP, Azure) en utilisant Terraform ou un service Kubernetes managé (EKS, GKE, AKS).

