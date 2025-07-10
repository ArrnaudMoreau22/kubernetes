
## Process
# This
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config

# Helm install
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash


# K9S
curl -LO https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz
tar -xvf k9s_Linux_amd64.tar.gz
sudo mv k9s /usr/local/bin/


# Alias
echo "alias k='kubectl'" >> ~/.bashrc && echo "alias h='helm'" >> ~/.bashrc && source ~/.bashrc


## Command helpful
# Helm create
cd app/
helm install mon-app .

# Helm upgrade
helm upgrade mon-app .

# Helm remove
helm uninstall mon-app


kubectl patch application keycloak -n argocd -p '{"metadata":{"finalizers":[]}}' --type=merge


curl -Lo kubelogin https://github.com/int128/kubelogin/releases/latest/download/kubelogin_linux_amd64.zip
unzip kubelogin_linux_amd64.zip
chmod +x kubelogin
sudo mv kubelogin /usr/local/bin/